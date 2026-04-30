## API 예외 처리
오류 발생시 오류 페이지(html)가 api 응답으로 전달되므로 api 예외처리 필수  
각 오류 상황에 맞는 오류 응답 스펙을 정하고 json으로 데이터 전송  
요청헤더의 Accept 값이 application/json이여야 기존 오류 응답이 안나감(*/* 불가능)  

````java
@RequestMapping(value = "/error-page/500", produces = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<Map<String, Object>> errorPage500Api(
        HttpServletRequest request, HttpServletResponse response) {
    
    log.info("api error page 500");
    HashMap<String, Object> result = new HashMap<>();
    Exception ex = (Exception) request.getAttribute(ERROR_EXCEPTION);
    result.put("status", request.getAttribute(ERROR_STATUS_CODE));
    result.put("message", ex.getMessage());

    Integer statusCode = (Integer) request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
    return new ResponseEntity<>(result, HttpStatus.valueOf(statusCode));
}
````

<br>

## 스프링 부트 기본 오류처리
BasicErrorController 내부에 이미 오류 처리 구현  
클라이언트 요청헤더의 Accept 값에 따라 오류 처리  

````java
@RequestMapping(produces = MediaType.TEXT_HTML_VALUE)
public ModelAndView errorHtml(HttpServletRequest request, HttpServletResponse response) {
  HttpStatus status = getStatus(request);
  Map<String, Object> model = Collections
      .unmodifiableMap(getErrorAttributes(request, getErrorAttributeOptions(request, MediaType.TEXT_HTML)));
  response.setStatus(status.value());
  ModelAndView modelAndView = resolveErrorView(request, response, status, model);
  return (modelAndView != null) ? modelAndView : new ModelAndView("error", model);
}

@RequestMapping
public ResponseEntity<Map<String, Object>> error(HttpServletRequest request) {
  HttpStatus status = getStatus(request);
  if (status == HttpStatus.NO_CONTENT) {
    return new ResponseEntity<>(status);
  }
  Map<String, Object> body = getErrorAttributes(request, getErrorAttributeOptions(request, MediaType.ALL));
  return new ResponseEntity<>(body, status);
}
````

<br>

## HandlerExceptionResolver
기본적으로 예외 발생후 서블릿을 넘어 WAS 도달시 상태코드가 500으로 처리  
컨트롤러 밖으로 예외가 던져진 경우 예외를 해결하고 새로운 동작 정의  
핸들러에서 예외발생시 afterCompletion 호출직전에 먼저 호출  
예외 해결 시도후 해결된 경우에 오류응답이 아닌 정상응답으로 처리(중간에서 오류를 건져냄)  

````java
public interface HandlerExceptionResolver {
    ModelAndView resolveException(HttpServletRequest request, 
        HttpServletResponse response, Object handler, Exception ex);
}
````

<br>

### resolver 구현
````java
@Slf4j
public class MyHandlerExceptionResolver implements HandlerExceptionResolver {
    @Override
    public ModelAndView resolveException(
            HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        try {
            if (ex instanceof IllegalArgumentException) {
                log.info("IllegalArgumentException resolver to 400");
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, ex.getMessage());
                return new ModelAndView();
            }
        } catch (IOException e) {
            log.error("resolver ex", ex);
        }
        return null;
    }
}
````

빈 ModelAndView 반환 : 뷰를 렌더링하지 않고 장상 흐름으로 서블릿이 리턴  
ModelAndView 지정 반환 : 뷰를 렌더링  
null 반환 : 다음 resolver 실행, 처리할 수 있는 resolver 없는 경우 기존 예외가 서블릿 밖으로 던져짐  
  
### resolver 등록
````java
@Override
public void extendHandlerExceptionResolvers(List<HandlerExceptionResolver> resolvers) {
    resolvers.add(new MyHandlerExceptionResolver());
}
````

<br>

## UserException
response.sendError() 통해서 오류 처리시 서블릿에서 다시 한번 서버에 요청 보내는 비효율  
resolver 안에서 응답을 완성하고 서블릿에선 정상처리  

````java
@Slf4j
public class UserHandlerExceptionResolver implements HandlerExceptionResolver {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public ModelAndView resolveException(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        try{
            if (ex instanceof UserException) {
                log.info("UserException resolver to 400");
                String acceptHeader = request.getHeader("accept");
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                if (acceptHeader.equals("application/json")) {
                    Map<String, Object> errorResult = new HashMap<>();
                    errorResult.put("ex", ex.getClass());
                    errorResult.put("message", ex.getMessage());

                    String messageBody = objectMapper.writeValueAsString(errorResult);

                    response.setContentType("application/json");
                    response.setCharacterEncoding("utf-8");
                    response.getWriter().write(messageBody);
                    return new ModelAndView();
                } else {
                    return new ModelAndView("error/500");
                }
            }
        } catch (IOException e) {
            log.error("resolver ex", e);
        }

        return null;
    }
}
````

<br>

## 스프링 HanlderExceptionResolverComposite
스프링에서 자동으로 ExceptionResolver 등록, 우선순위 존재  
  
1. ExceptionHandlerExceptionResolver  

2. ResponseStatusExceptionResolver  

        사용자 지정 예외에 따라서 Http 상태코드 지정
        어노테이션 적용불가한 시스템 예외에는 ResponseStatusException 사용
        response.sendError() 방식
        reason 파라미터로 MessageSource의 key 값 사용가능

      ````java
      @ResponseStatus(code = HttpStatus.BAD_REQUEST, reason = "잘못된 요청 오류")
      public class BadRequestException extends RuntimeException {
      }
      
      @GetMapping("/api/response-status-ex2") 
      public String responseStatusEx2() {
          throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "잘못된 요청 오류", 
                  new IllegalArgumentException());
      }
      ````
      
3. DefaultHandlerExceptionResolver  

        스프링 내부에서 발생하는 기본 예외처리
        대표적으로 파라미터 바인딩 실패로 인해 TypeMismatchException 발생시 400 오류응답
        response.sendError() 방식

<br>

## ExceptionHandlerExceptionResolver
스프링은 API 예외 처리 문제를 해결하기 위해서 @ExcetionHandler 어노테이션 지원  
컨트롤러마다 @ExcetionHandler 어노테이션을 사용한 오류에 대해 각기 다른 처리(json 형식으로 반환)  
하지만 이런 처리 방식은 오류를 잡아 정상처리하므로 상태코드가 200(@ResponseStatus 어노테이션으로 변경)  
지정된 예외 또는 그 예외의 자식 클래스는 모두 잡힘  
response.sendError() 방식이 아닌 @ExceptionHandler 어노테이션에서 json 형식으로 응답처리  

````java
@Slf4j
@RestController
public class ApiExceptionV2Controller {
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(IllegalArgumentException.class)
    public ErrorResult illegalExHandler(IllegalArgumentException e) {
        log.error("[exceptionHandler] ex", e);
        return new ErrorResult("BAD", e.getMessage());
    }
    
    @ExceptionHandler
    public ResponseEntity<ErrorResult> userExHandler(UserException e) {
        log.error("[exceptionHandler] ex", e);
        ErrorResult errorResult = new ErrorResult("USER-EX", e.getMessage());
        return new ResponseEntity<>(errorResult, HttpStatus.BAD_REQUEST);
    }
    
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ExceptionHandler
    public ErrorResult exHandler(Exception e) {
        log.error("[exceptionHandler] ex", e);
        return new ErrorResult("EX", "내부 오류");
    }
    
    //여러 매핑 컨트롤러 함수
    ...
}
````

<br>

## ControllerAdvice
@ExceptionHandler 어노테이션 사용시 정상코드와 예외처리코드가 하나의 컨트롤러 안에 존재  
@ControllerAdvice 또는 @RestControllerAdvice 어노테이션 사용으로 분리가능  
여러 컨트롤러에서의 공통 오류 처리  
대상을 지정하지 않으면 모든 컨트롤러에 적용  

````java
    @Slf4j
    @RestControllerAdvice
    public class ExControllerAdvice {

        @ResponseStatus(value = HttpStatus.BAD_REQUEST)
        @ExceptionHandler(IllegalArgumentException.class)
        public ErrorResult illegalExHandler(IllegalArgumentException e) {
            log.error("[exceptionHandler] ex", e);
            return new ErrorResult("BAD", e.getMessage());
        }

        @ExceptionHandler
        public ResponseEntity<ErrorResult> userExHandler(UserException e) {
            log.error("[exceptionHandler] ex", e);
            ErrorResult errorResult = new ErrorResult("USER-EX", e.getMessage());
            return new ResponseEntity<>(errorResult, HttpStatus.BAD_REQUEST);
        }

        @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
        @ExceptionHandler
        public ErrorResult exHandler(Exception e) {
            log.error("[exceptionHandler] ex", e);
            return new ErrorResult("EX", "내부 오류");
        }
    }
````

<br>

## 글로벌 설정이 아닌 특정 컨트롤러 지정가능
1. 특정 어노테이션  
    ````java
    @ControllerAdvice(annotations = RestController.class)
    ````

2. 특정 패키지   
    ````java
    @ControllerAdvice("org.example.controllers")
    ````

3. 특정 컨트롤러   
    ````java
    @ControllerAdvice(assignableTypes = {ControllerInterface.class, AbstractController.class})
    ````

<br>
