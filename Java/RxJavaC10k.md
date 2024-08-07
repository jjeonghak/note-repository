## C10k 문제
단일 서버에서 1만 개의 동시 접속 처리와 최적화 연구 영역  
쉽게 달성하는 리액티브 접근 방식 존재  
전통적인 소켓 당 스레드 모델은 잘 동작하지만 특정 수준의 동시성에 도달하면 스레드의 갯수는 위험  
특히 Keep-Alive 헤더가 붙은 서버 전송 이벤트, 웹소켓 TCP/IP 연결인 경우   

<br>

## 전통적인 스레드 기반 HTTP 서버
1. 단일 스레드 서버  
    가장 단순한 구현, 그저 ServerSocket을 열어서 접속 요청이 오는대로 처리  
    하나의 요청동안 다른 요청은 모두 대기열에서 대기  

    ````java
    class SingleThread {
        public static final byte[] RESPONSE = (
            "HTTP/1.1 200 OK\r\n" +
            "Content-length: 2\r\n\r\n" +
            "OK"
        ).getBytes();

        public static void main(String[] args) throws IOException {
            final ServerSocket serverSocket = new ServerSocket(8080, 100);  //최대 100개까지 대기
            while (!Thread.currentThread().isInterrupted()) {
                final Socket client = serverSocket.accept();  //클라이언트 접속까지 블록
                handle(client);
            }
        }

        private static void handle(Socket client) {
            try {
                while (!Thread.currentThread().isInterrupted()) {
                    readFullRequest(client);
                    client.getOutputStream().write(RESPONSE);
                }
            } catch (Exception e) {
                e.printStackTrace();
                IOUtils.closeQuietly(client);
            }
        }

        private static void readFullRequest(Socket client) throws IOException {
            BufferedReader reader = new BufferedReader(new InputStreamReader(client.getInputStream()));
            String line = reader.readLine();
            while (line != null && !line.isEmpty()) {
                line = reader.readLine();
            }
        }
    }
    ````

<br>

2. 네티와 RxNetty를 사용한 논블로킹 HTTP 서버  
    이벤트 주도 방식의 HTTP 서버  
    메모리 소비 감소, 더 나은 CPU 및 캐시 활용, 단일 노드에서 크게 향상된 확장성  
    대신 단숨함과 명료함은 포기  
    데이터를 주고 받을때 블로킹하지 않음  
    대신 ByteBuf 인스턴스 형태의 바이트를 전송 처리 파이프라인으로 밀어냄  
    TCP/IP는 데이터 청크를 전송하고 이를 올바른 순서로 조합하여 스트림과 같이 보이게 하는 역할은 운영체제의 몫  
    네티는 이런 추상화를 제거하고 바이트 시퀀스 계층에서 동작  
    몇 바이트 단위로 도착할때마다 핸들러에 알리고 사용자는 블로킹 없이 ChannelFuture를 받음  

    ````java
    class HttpTcpNettyServer {
        public static void main(String[] args) throws Exception {
            EventLoopGroup bossGroup = new NioEventLoopGroup(1);  //들어오는 연결을 받는 풀
            EventLoopGroup workerGroup = new NioEventLoopGroup(); //이벤트를 처리하는 풀   
            try {
                new ServerBootstrap()
                    .option(ChannelOption.SO_BACKLOG, 50_000)
                    .group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .childHandler(new HttpInitializer())
                    .bind(8080)
                    .sync()
                    .channel()
                    .closeFuture()
                    .sync();
            } finally {
                bossGroup.shutdownGracefully();
                workerGroup.shutdownGracefully();
            }
        }
    }

    class HttpInitializer extends ChannelInitializer<SocketChannel> {
        private final HttpHandler httpHandler = new HttpHandler();

        @Override
        public void initChannel(SocketChannel ch) {
            ch.pipeline()
              .addLast(new HttpServerCodec())  //도착한 원시 바이트를 HTTP 요청 객체로 디코딩
              .addLast(httpHandler);           //인코딩할때도 사용
        }
    }

    @Sharable
    class HttpHandler extends ChannelInboundHandlerAdapter {
        @Override
        public void channelReadComplete(ChannelHandlerContext ctx) {
            ctx.flush();
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof HttpRequest) {
                final DefaultFullHttpResponse response = new DefaultFullHttpResponse(
                    HTTP_1_1,
                    HttpResponseStatus.OK,
                    Unpooled.wrappedBuffer("OK".getBytes(UTF_8))
                );
                response.headers().add("Context-length", 2);
                ctx.writeAndFlush(response);
                  //.addListener(ChannelFutureListener.CLOSE); 채널을 닫으면 연결도 닫힘
            }
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
            log.error("Error", cause);
            ctx.close();
        }
    }
    ````

<br>

3. RxNetty를 사용한 Observable 서버  
    네티는 아카, 엘리스틱서치, 호넷Q 등 성공적인 제품의 뼈대를 구성하는 중요한 요소  
    RxNetty는 RxJava와 네티 API를 연결하는 얇은 래퍼  

    ````java
    class EurUsdCurrencyTcpServer {
        private static final BigDecimal RATE = new BigDecimal("1.06448");
    
        public static void main(Stringp[] args){
            TcpServer
                .newServer(8080)
                .<String, String>pipelineConfigurator(pipeline -> {
                    pipeline.addLast(new LineBasedFrameDecoder(1024));  //ByteBuf 순열을 재정렬하여 여러 줄로 이루어진 목록으로 변경
                    pipeline.addLast(new StringDecoder(UTF_8));
                })
                .start(con -> {
                    Observable<String> output = con
                        .getInput()
                        .map(BigDecimal::new)
                        .flatMap(eur -> eurToUsd(eur));
                    return con.writeAndFlushOnEach(output);
                })
                .awaitShutdown();
        }
    
        static Observable<String> eurToUsd(BigDecimal eur) {
            return Observable
                .just(eur.multiply(RATE))
                .map(amount -> eur + " EUR is" + amount + " USD\n")
                .delay(1, TimeUnit.SECONDS);
        }
    }
    
    class HttpTcpRxNettyServer {
        public static final Observable<String> RESPONSE = Observale.just(
            "HTTP/1.1 200 OK\r\n" +
            "Content-length: 2\r\n\r\n" +
            "OK"
        );
    
        public static void main(String[] args) {
            TcpServer
                .newServer(8080)
                .<String, String>pipelineConfigurator(pipeline -> {
                    pipeline.addLast(new LineBasedFrameDecoder(128));
                    pipeline.addLast(new StringDecoder(UTF_8));
                })
                .start(con -> {
                    Observable<String> output = con
                        .getInput()
                        .flatMap(line -> {
                            if (line.isEmpty()) {
                                return RESPONSE;
                            } else {
                                return Observable.empty();
                            }
                        });
                    return con.writeAndFlushOnEach(output);
                })
                .awaitShutdown();
        }
    }
    
    class RxNettyHttpServer {
        private static final Observable<String> RESPONSE_OK = Observable.just("OK");
    
        public static void main(String[] args) {
            HttpServer
                .newServer(8086)
                .start((req, res) -> 
                    res.setHeader(CONTENT_LENGTH, 2)
                        .writeStringAndFlushOnEach(RESPONSE_OK)
                ).awaitShutdown();
        }
    }
    
    class RestCurrencyServer {
        private static final BigDecimal RATE = new BigDecimal("1.06448");
    
        public static void main(String[] args) {
            HttpServer
                .newServer(8080)
                .start((req, res) -> {
                    String amountStr = req.getDecodedPath().substring(1);
                    BigDecimal amount = new BigDecimal(amountStr);
                    Observable<String> response = Observable
                        .just(amount)
                        .map(eur -> eur.multiply(RATE))
                        .map(usd -> 
                            "{\"EUR\": " + amount + ", " + 
                            "\"USD\": " + usd + "}");
                    return resp.writeString(response);
                }).awaitShutdown();
        }
    }
    ````

<br>

## RxNetty Client
네티를 적용한 RxJava는 네트워크가 작동하는 방식에 충분히 근접한 추상화 제공  
클라이언트 측 RxNetty는 간결한 API 제공  

### 단일 url 연결
````java
Observable<ByteBuf> response = HttpClient
    .newClient("example.com", 80)
    .createGet("/")
    .flatMap(HttpClientResponse::getContent);
response
    .map(bb -> bb.toString(UTF_8))
    .subscribe(System.out::println);
````

<br>

### 동적 url, 각기 출처가 다른 ByteBuf 메시지를 뒤섞는 인위적인 예제
````java
Observalbe<URL> sources = ...
Observable<ByteBuf> packets = sources
    .flatMap(url -> HttpClient
        .newClient(url.getHost(), url.getPort())
        .createGet(url.getPath()))
    .flatMap(HttpClientResponse::getContent);
````

<br>

