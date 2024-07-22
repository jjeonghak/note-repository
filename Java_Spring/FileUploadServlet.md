## 파일 업로드
기본적인 문자 전송방법은 HTML 폼 데이터를 서버로 전송하는 방법(application/x-www-form-urlencoded)  
파일은 문자가 아닌 바이너리 데이터로 전송해야함  
여러가지 타입의 데이터를 동시에 전송(form 태그에 enctype="multipart/form-data" 추가)  
설정한 boundary를 기준으로 헤더, 공백, 바디가 포함(마지막 boundary에는 "--"추가)  
항목별 Content-Dispostion 헤더추가로 부가 정보 기입  
파일의 경우 Content-Type 헤더가 추가되고 바이너리 데이터로 전송  

````html
<form action="/save" method="post" enctype="multipart/form-data">
````

````
[HTTP]
POST /save HTTP/1.1
Host: localhost:8080
Content-Type: multipart/form-data; boundary=-----XXX
...
-----XXX
Content-Disposition: form-data; name="username"

kim jeong han
-----XXX
Content-Disposition: form-data; name="age"

26
-----XXX
Content-Disposition: form-data; name="file1"; filename="intro.png"
Content-Type: image/png

109238a9o0p3eqwokjasd09ou3oirjwoe9u34ouief...
-----XXX--
````

<br>

## multipart
application/x-www-form-urlencoded 타입과 비교해서 매우 복잡  
각각의 부분을 part로 분할  
전송된 데이터의 사이즈를 제한해야 SizeLimitExceededException 예외 발생 방지  
전송된 데이터를 저장할 폴더 경로 설정 필수(경로 마지막에 "/" 추가)  
스프링의 DispatcherServlet에서 MultipartResolver 실행  
멀티파트 요청이 온 경우 RequestFacade -&gt; StandardMultipartHttpServletRequest 변환  

````yml
spring.servlet.multipart.max-file-size=1MB
spring.servlet.multipart.max-request-szie=10MB
spring.servlet.multipart.enable=true
file.dir=/Users/macbookpro/Desktop/file/
````

````java
@Slf4j
@Controller
@RequestMapping("/servlet/v2")
public class ServletUploadControllerV2 {

    @Value("${file.dir}")
    private String fileDir;

    @GetMapping("/upload")
    public String newFile() {
        return "upload-form";
    }

    @PostMapping("/upload")
    public String saveFileV1(HttpServletRequest request) throws ServletException, IOException {
        log.info("request={}", request);

        String itemName = request.getParameter("itemName");
        log.info("itemName={}", itemName);

        Collection<Part> parts = request.getParts();
        log.info("parts={}", parts);

        for (Part part : parts) {
            log.info("==== PART ====");
            log.info("name={}", part.getName());
            Collection<String> headerNames = part.getHeaderNames();
            for (String headerName : headerNames) {
                log.info("header {}: {}", headerName, part.getHeader(headerName));
            }
            log.info("submittedFilename={}", part.getSubmittedFileName());
            log.info("size={}", part.getSize());
            
            //데이터 읽기
            InputStream inputStream = part.getInputStream();
            String body = StreamUtils.copyToString(inputStream, StandardCharsets.UTF_8);
            log.info("body={}", body);
            
            //파일 저장
            if (StringUtils.hasText(part.getSubmittedFileName())) {
                String fullPath = fileDir + part.getSubmittedFileName();
                log.info("save file fullPath={}", fullPath);
                part.write(fullPath);
            }
        }
        return "upload-form";
    }
}
````

````
part.getSubmittedFileName() : 클라이언트가 전달한 파일
part.getInputStream() : 전송데이터 읽기
part.write(...) : 전송데이터 저장
````

<br>
