## Future
자바 5부터 미래의 어느 시점에 결과를 얻는 모델에 활용가능한 Future 인터페이스 제공  
계산이 끝났을 때 결과에 접근할 수 있는 참조 제공  
오랜 시간이 걸리는 작업을 내부로 설정하면 호출자 스레드는 결과 대기하는 동안 다른 작업 수행 가능  
Callable 객체 내부로 감싼 후에 ExecutorService에 제출  

````java
//비동기 Future 실행
ExecutorService executor = Executors.newCachedThreadPool();
Future<Double> future = executor.submit(new Callable<Double>() {  //Executor 스레드 비동기 작업 진행
    public Double call() {
        return doSomeLongComputation();   //오랜 시간이 걸리는 작업
    }
});
doSomethingElse();  //비동기 작업을 수행하는 동안 현재 스레드는 다른 작업 진행
try {
    Double result = future.get(1, TimeUnit.SECOND); //비동기 작업 결과 조회, 호출 스레드 1초까지만 블록
} catch (ExecutionException ee) {
    //계산 중 예외 발생
} catch(InterruptedException ie) {
    //현재 스레드에서 대기 중 인터럽트 발생
} catch(TimeoutException te) {
    //Future 완료 전 타임아웃 발생
}
````

<br>
  
## Future 제한
선언형 기능이 존재하지 않음  

1. 두 개의 비동기 계산 결과를 하나로 병합  
2. Future 집합이 실행하는 모든 태스크의 완료 대기  
3. Future 집합에서 가장 빠른 결과를 반환  
4. 프로그램적으로 Future 완료(비동기 동작에 수동으로 결과 제공)  
5. Future 완료 동작에 반응  

<br>

## 동기 및 비동기
전통적인 동기 API에서는 메서드 호출 후 계산을 완료할때까지 대기  
메서드 결과가 반환되면 호출자는 반환된 값으로 다른 동작 수행  
블록 호출(blocking call) : 호출자와 피호출자가 다른 스레드라도 호출자는 피호출자의 결과를 대기  

<br>

비동기 API에서는 메서드가 즉시 반환되며 끝내지 못한 나머지 작업을 호출자 스레드와 동기적으로 실행가능한 다른 스레드 할당  
비블록 호출(non-blocking call) : 호출자와 피호춣자가 다른 스레드로 결과를 대기하지 않고 각각 수행  
다른 스레드에 할당된 나머지 계산 결과는 콜백 메서드 또는 대기 메서드로 호출자에게 전달  

<br>

## CompletableFuture
Future 인터페이스 구현체  
Stream과 유사한 패턴으로 람다 표현식과 파이프라이닝 활용  

````java
//1초 지연 메서드
public static void delay() {
    try {
        Thread.sleep(1000L);
    } catch (InterruptedException e) {
        throw new RuntimeException(e);
    }
}

//동기 API
public double getPrice(String product) {
    return calculatePrice(product);
}

private double calculatePrice(String product) {
    delay();  //동기 API 블록 호출
    return random.nextDouble() * product.charAt(0) + product.charAt(1);
}

//바동기 API 변환
public Future<Double> getPriceAsync(String product) {
    CompletableFuture<Double> futurePrice = new CompletableFuture<>();
    new Thread(() -> {
        double price = calculatePrice(product);   //다른 스레드에서 비동기적 계산 수행
        futurePrice.complete(price);              //오랜 시간이 걸리는 작업 완료 후 Future에 값 설정
    }).start();
    return futurePrice;   //계산 결과 대기하지 않고 바로 Future 반환
}

//비동기 API 사용
Shop shop = new Shop("DemoShop");
long start = System.nanoTime();
Future<Double> futurePrice = shop.getPriceAsync("product");
long invocationTime = ((System.nanoTime() - start) / 1_000_000);
System.out.println("* Invocation returned after " + invocationTime + " msecs");
doSomethingElse();
try {
    double price = futurePrice.get();   //결과 존재시 조회, 아닌 경우 블록
    System.out.printf("* Price is %.2f\n", price);
} catch (Exception e) {
    throw new RuntimeException(e);
}
long retrievalTime = ((System.nanoTime() - start) / 1_000_000);
System.out.println("* Price returned after " + retrievalTime + " msecs");
````

````
* Invocation returned after 43 msecs
* Price is 123.26
* Price returned after 1045 msecs
````

<br>

## 오류 처리
비동기적으로 스레드가 작업하는 과정 중에 오류 발생시 해당 스레드만 영향  
결과적으로 클라이언트는 get 메서드가 반환될 때까지 계속 블록 상태로 대기  
타임아웃값을 받는 get 메서드 오버로드 버전으로 해결가능하나 오류의 원인은 알 수 없음  
completeExceptionally 메서드를 활용해 클라이언트로 전달 가능  

````java
//CompleteableFuture 내부 오류 전파
public Future<Double> getPriceAsync(String product) {
    CompletableFuture<Double> futurePrice = new CompletableFuture<>();
    new Thread(() -> {
        try {
            double price = calculatePrice(product);
            futurePrice.complete(price);
        } catch (Exception ex) {
            //ExecutionException 오류 발생
            futurePrice.completeExceptionally(ex);  //발생한 오류를 포함시켜 Future 종료
        }
    }).start();
    return futurePrice;
}
````

## 팩토리 메서드 활용
supplyAsync 팩토리 메서드는 Supplier 인수로 CompletableFuture 반환  
해당 메서드는 오류 전파까지 구현  

````java
public Future<Double> getPriceAnsyc(String product) {
    return CompletableFuture.supplyAsync(() -> calculatePrice(product));
}
````

<br>

## 비블록 코드
병렬 처리와 비동기 처리는 Runtime.getRuntime().availableProcessors()로 반환된 스레드 수를 사용  
CompletableFuture 클래스는 병렬 스트림보다 작업에 이용 가능한 Executor 지정 가능  
I/O가 포함되지 않는 계산 중심의 동작은 스트림 병렬  
I/O를 대기하는 작업을 병렬로 처리하는 동작은 CompletableFuture  

````java
List<Shop> shops = Arrays.asList(new Shop("DemoShop1"),
    new Shop("DemoShop2"), ...);

//순차적으로 정보를 요청
public List<String> findPrices(String product) {
    return shops.stream()
        .map(s -> String.format("%s price is %.2f", s.getName(), s.getPrice(product)))
        .collect(toList());
    //Done in 4023 msecs
}

//병렬 스트림
public List<String> findPrices(String product) {
    return shops.parallelStream()
        .map(s -> String.format("%s price is %.2f", s.getName(), s.getPrice(product)))
        .collect(toList());
    //Done in 1180 msecs
}

//비동기 호출
public List<String> findPrices(String product) {
    List<CompletableFuture<String>> priceFutures = shops.stream()
        .map(s -> CompletableFuture.supplyAsync(
            () -> String.format("%s price is %.2f", s.getName(), s.getPrice(product)))))
        .collect(toList());
    //한 파이프라인 스트림으로 처리한 경우 게으른 특성으로 동기적, 순차적으로 결과 반환
    return priceFutures.stream()
        .map(CompletableFuture::join)   //모든 비동기 작업 대기
        .collect(toList());
    //Done in 2005 msecs
}
````

<br>

## Custom Executor
실제로 필요한 작업량을 고려한 풀 스레드 수에 맞는 Executor 생성으로 성능 향상 가능  
스레드 풀이 큰 경우 CPU 및 메모리 자원을 서로 경쟁  
스레드 풀이 작은 경우 CPU 일부 코어는 활용되지 않음  
데몬 스레드는 일반 스레드와 다르게 자바 프로그램의 종료에 관여하지 않음  

````
//게츠 CPU 활용 비율 공식
Nthreads = Ncpu * Ucpu * (1 + W/C)
Ncpu : Runtime.getRuntime().availableProcessors() 반환 코어 수
Ucpu : 0 ~ 1 사이의 CPU 활용 비율
W/C : 대기시간과 계산시간 비율
````

<br>

````java
//상점 갯수를 고려한 Executor
private final Executor executor = Executors.newFixedThreadPool(
    Math.min(shops.size(), 100), 
    new ThreadFactory() {
        public Thread newThread(Runnalbe r) {
            Thread t = new Thread(r);
            t.setDaemon(true);    //데몬 스레드 사용
            return t;
        }
});

List<CompletableFuture<String>> priceFutures = shops.stream()
        .map(s -> CompletableFuture.supplyAsync(
            () -> String.format("%s price is %.2f", s.getName(), s.getPrice(product)))),
            executor)
        .collect(toList());

//Done in 1022 msecs
````

<br>

## 비동기 작업 파이프 라인
thenApply 메서드와 thenCompose 메서드를 이용해서 비동기 체인 연결  

````java
//순차적으로 정보를 요청
public List<String> findPrices(String product) {
    return shops.stream()
        .map(shop -> shop.getPrice(product))
        .map(Quote::parse)
        .map(Discount::applyDiscount)
        .collect(toList());
    //Done in 10028 msecs
}

//비동기 호출
public List<String> findPrices(String product) {
    List<CompletableFuture<String>> priceFutures = shops.stream()
        .map(shop -> CompletableFuture.supplyAsync(
            () -> shop.getPrice(product), executor)
        .map(future -> future.thenApply(Quote::parse))  //비동기 스레드 내에서 동기적으로 수행, map
        .map(future -> future.thenCompose(              //종속 비동기 작업 체인을 연결, flapMap
            quote -> CompletableFuture.supplyAsync(
                () -> Discount.applyDiscount(quote), executor)))
        .collect(toList());
    return priceFutures.stream()
        .map(CompletableFuture::join)
        .collect(toList());
}
````

<br>


## 독립된 CompletableFuture
독립된 두 개의 CompletableFuture 결과를 병합하는 경우 thenCombine 메서드 사용  
인수로 Bifunction을 받아 두 개의 CompletableFuture 결과를 어떤 식으로 병합할지 결정  

````java
//독립된 CompletableFuture 병합
Future<Double> futurePriceInUSD = CompletableFuture.supplyAsync(      //첫번째 태스크
        () -> shop.getPrice(product))
    .thenCombine(
        CompletableFuture.supplyAsync(
                () -> exchangeService.getRate(Money.EUR, Money.USD)), //두번째 태스크
           (price, rate) -> price * rate                              //두 결과 병합
    ));
````

<br>

## 타임아웃
무한정 대기하는 상황을 방지하기 위해 블록을 하지 않거나 타임아웃 설정 필요  

````java
Future<Double> futurePriceInUSD = CompletableFuture.supplyAsync(
        () -> shop.getPrice(product))
    .thenCombine(
        CompletableFuture.supplyAsync(
            () -> exchangeService.getRate(Money.EUR, Money.USD))
            .completeOnTimeout(DEFAULT_RATE, 1, TimeUnit.SECOND),   //태스크가 1초 내로 끝나지 않으면 기본값
        (price, rate) -> price * rate
    ))
    .orTimeout(3, TimeUnit.SECOND);      //3초 내로 파이프라인이 끝나지 않으면 Future가 TimeoutException 발생
````

<br>

## 결과 처리
Consumer 인수로 thenAccept 메서드를 사용  
thenAccept 내에서 인수를 소비하므로 반환값은 CompletableFuture<Void>  

````java
public Stream<CompletableFuture<String>> findPricesStream(String product) {
    return shops.stream()
        .map(shop -> CompletableFuture.supplyAsync(
            () -> shop.getPrice(product), executor))
        .map(future -> future.thenApply(Quote::parse))
        .map(future -> future.thenCompose(quote -> 
            CompletableFuture.supplyAsync(
                () -> Discount.applyDiscount(quote))))
}

CompletableFuture[] futures = findPricesStream("product")
    .map(f -> f.thenAccept(System.out::println))
    .toArray(size -> new CompletableFuture[size]);    //발생 순서대로 스트림의 요소를 포함하는 배열을 반환
CompletableFuture.allOf(futures).join();              //실행 완료 대기
````

<br>



