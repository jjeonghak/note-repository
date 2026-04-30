## 오류페이지
이전의 오류페이지는 스프링을 사용하지 않고 직접 정의  

````java
@Component
public class WebServerCustomizer implements WebServerFactoryCustomizer<ConfigurableServletWebServerFactory> {
    @Override
    public void customize(ConfigurableServletWebServerFactory factory) {

        ErrorPage errorPage404 = new ErrorPage(HttpStatus.NOT_FOUND, "/error-page/404");
        ErrorPage errorPage500 = new ErrorPage(HttpStatus.INTERNAL_SERVER_ERROR, "/error-page/500");
        ErrorPage errorPageEx = new ErrorPage(RuntimeException.class, "/error-page/500");

        factory.addErrorPages(errorPage404, errorPage500, errorPageEx);
    }
}

@Slf4j
@Controller
public class ServletExController {

    @GetMapping("/error-ex")
    public void errorEx() {
        throw new RuntimeException("예외 발생");
    }

    @GetMapping("/error-404")
    public void error404(HttpServletResponse response) throws IOException {
        response.sendError(404, "404 error");
    }

    @GetMapping("/error-400")
    public void error400(HttpServletResponse response) throws IOException {
        response.sendError(400, "400 error");
    }

    @GetMapping("/error-500")
    public void error500(HttpServletResponse response) throws IOException {
        response.sendError(500);
    }
}

@Slf4j
@Controller
public class ErrorPageController {

    //상수로 정의되어 있는 에러코드
    public static final String ERROR_EXCEPTION = "javax.servlet.error.exception";
    public static final String ERROR_EXCEPTION_TYPE = "javax.servlet.error.exception_type";
    public static final String ERROR_MESSAGE = "javax.servlet.error.message";
    public static final String ERROR_REQUEST_URI = "javax.servlet.error.request_uri";
    public static final String ERROR_SERVLET_NAME = "javax.servlet.error.servlet_name";
    public static final String ERROR_STATUS_CODE = "javax.servlet.error.status_code";

    @RequestMapping("/error-page/404")
    public String errorPage404(HttpServletRequest request, HttpServletResponse response) {
        log.info("errorPage 404");
        printErrorInfo(request);
        return "error-page/404";
    }

    @RequestMapping("/error-page/500")
    public String errorPage500(HttpServletRequest request, HttpServletResponse response) {
        log.info("errorPage 500");
        printErrorInfo(request);
        return "error-page/500";
    }

    private void printErrorInfo(HttpServletRequest request) {
        log.info("ERROR_EXCEPTION: {}", request.getAttribute(ERROR_EXCEPTION));
        log.info("ERROR_EXCEPTION_TYPE: {}", request.getAttribute(ERROR_EXCEPTION_TYPE));
        log.info("ERROR_MESSAGE: {}", request.getAttribute(ERROR_MESSAGE));
        log.info("ERROR_REQUEST_URI: {}", request.getAttribute(ERROR_REQUEST_URI));
        log.info("ERROR_SERVLET_NAME: {}", request.getAttribute(ERROR_SERVLET_NAME));
        log.info("ERROR_STATUS_CODE: {}", request.getAttribute(ERROR_STATUS_CODE));
        log.info("dispatchType={}", request.getDispatcherType());
    }
}
````

<br>

## 스프링 부트 오류 페이지
ErrorPage 자동 등록(/error 기본 경로)  
BasicErrorController 자동 등록(ErrorMvcAutoConfiguration 클래스가 자동 등록)  
상태코드와 예외를 설정하지 않으면 new ErrorPage("/error") 기본 오류페이지로 사용  
개발자는 오류 페이지 화면만 등록  

<br>
  
## 오류 페이지 우선순위
1. 뷰 템플릿  

        resources/templates/error/500.html
        resources/templates/error/5xx.html
  
2. 정적 리소스  

        resources/static/error/400.html
        resources/static/error/404.html
        resources/static/error/4xx.html
    
3. 적용 대상이 없는 경우 error.html
 
        resources/templates/error.html

<br>

## BasicErrorController 기본정보
컨트롤러를 통해 model에 기본정보들을 담아 뷰 템플릿에서 사용가능  
하지만 오류정보는 실무에서 노출하면 안됨, 서버로그로 남겨서 보관  

    timestamp : Fri Feb 05 00:00:00 KST 2022
    status : 400
    error : Bad Request
    exception : org.springframework.validation.BindException
    trace : 예외 trace
    message : Validation failed for object='data'. Error count: 1
    errors : Errors(BindResult)
    path : 클라이언트 요청 경로

````yml
server.error.path=/error
server.error.whitelabel.enabled=false
server.error.include-exception=true
server.error.include-message=on_param
server.error.include-stacktrace=on_param
server.error.include-binding-errors=on_param
````
    always : 항상 사용
    never : 사용하지 않음
    on_param : 파라미터 존재시 사용

<br>
