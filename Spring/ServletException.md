## 서블릿 예외 처리
1. Exception  
2. response.sendError(HTTP 상태 코드, 오류 메시지)  

<br>

## Exception

### 자바 직접 실행 
자바의 메인 메서드 실행하는 경우 main이라는 이름의 쓰레드가 실행  
실행 도중에 예외를 잡지 못하고 main() 메서드를 넘어서 예외가 던져지면, 예외 정보를 남기고 해당 쓰레드 종료  

<br>
    
### 웹 어플리케이션
사용자 요청별로 쓰레드가 할당되고, 서블릿 컨테이너 안에서 실행  
예외 발생시 try-catch 구문으로 예외를 잡지못하면 서블릿 밖으로 예외가 전달(WAS까지)  

      WAS(여기까지 전파) <- 필터 <- 서블릿 <- 인터셉터 <- 컨트롤러(예외발생)
      WAS '/error-page' 다시 요청 -> 필터 -> 서블릿 -> 인터셉터 -> 컨트롤러 -> 뷰
    
오류 발생시 오류 페이지 출력을 위해 필터, 서블릿, 인터셉터 모두 다시 호출(비효율)  
요청이 클라이언트와 서버중 어느 요청인지 DispatcherType 추가정보   
웹브라우저에서 개발자 모드로 확인해보면 HTTP 상태코드 500(서버까지 요청이 왔지만 처리불가이므로)  
기본 화이트레이블 페이지 비활성화  

<br>

````yaml
server.error.whitelabel.enabled=false
````

````java
@Slf4j
@Controller
public class ServletExController {
    @GetMapping("/error-ex")
    public void errorEx() {
        throw new RuntimeException("error");
    }
}
````

<br>

## response.sendError(HTTP 상태코드, 오류 메시지)
호출 당시 예외가 발생하는 것이 아닌 서블릿 컨테이너에게 오류 발생한 사실을 전달  
서블릿 컨테이너는 고객에게 응답 전 response.sendError() 호출 유무를 판별하고 오류코드에 맞는 기본 오류페이지 렌더링  

    WAS(sendError 호출기록확인) <- 필터 <- 서블릿 <- 인터셉터 <- 컨트롤러(response.sendError())

<br>

````java
@Slf4j
@Controller
public class ServletExController {
    @GetMapping("/error-ex")
    public void errorEx() {
        throw new RuntimeException("예외 발생");
    }

    @GetMapping("/error-404")
    public void error404(HttpServletResponse response) throws IOException {
        response.sendError(HttpServletResponse.SC_NOT_FOUND, "404 error");
    }

    @GetMapping("/error-500")
    public void error500(HttpServletResponse response) throws IOException {
        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "500 error");
    }
}
````

<br>

## 서블릿 오류 화면제공

서블릿 컨테이너가 제공하는 기본 예외처리화면은 고객 친화적이지 않음

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
````

<br>

오류페이지 처리를 위한 컨트롤러도 필요
````java
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

## DispatcherType
클라이언트 요청인 경우 request.getDispatcherType() == REQUEST  
서버 오류 처리 요청인 경우 request,getDispatcherType() == ERROR  
필터 설정시 필터가 작용하는 DispatcherType 설정가능  

````java
filterFilterRegistrationBean.setDispatcherTypes(DispatcherType.REQUEST);
````

````java
public enum DispatcherType {
    FORWARD,  //서블릿에서 다른 서블릿이나 JSP 호출시 RequestDispatcher.forward(request, response);
    INCLUDE,  //서블릿에서 다른 서블릿이나 JSP 결과 포함시 RequestDispatcher.include(request, response);
    REQUEST,  //클라이언트 요청
    ASYNC,    //서블릿 비동기 호출
    ERROR     //서버 오류 요청
}
````

<br>
