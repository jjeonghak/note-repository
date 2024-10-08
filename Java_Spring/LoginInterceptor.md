## 스프링 인터셉터
서블릿 필터와 같이 웹과 관련된 공통관심사항을 처리  
서블릿 필터는 서블릿이 제공, 스프링 인터셉터는 스프링 mvc가 제공  
서블릿 필터보다 편리하고 정교한 기능 지원  
디스패처 서블릿이 스프링 mvc의 시작이므로 서블릿 이후 인터셉터 등장  

<br>

## 인터셉터 흐름
로그인 사용자 : HTTP 요청 -&gt; WAS -&gt; 필터 -&gt; 서블릿 -&gt; 스프링 인터셉터 -&gt; 컨트롤러  
비로그인 사용자 : HTTP 요청 -&gt; WAS -&gt; 필터 -&gt; 서블릿 -&gt; 스프링 인터셉터(적절하지 않은 요청처리, 컨트롤러 호출 안함)  
인터셉터 체인 : HTTP 요청 -&gt; WAS -&gt; 필터 -&gt; 서블릿 -&gt; 인터셉터1 -&gt; 인터셉터2 -&gt; 컨트롤러  

<br>

## 인터셉터 인터페이스
인터셉터가 컨트롤러를 호출할 때 단계적으로 세분화  

````java
pulbic interface HandlerInterceptor {
    //컨트롤러 호출 직전에 호출
    default boolean preHandle(HttpServletRequest request, HttpServletResponse response,
        Object handler) throws Exception {}
    //컨트롤러 호출 후에 호출
    default void postHandle(HttpSerlvetRequest request, HttpServletResponse response,
        Object handler, @Nullable ModelAndView modelAndView) throws Exception {}
    //요청이 완료된 후에 호출
    default void afterCompletion(HttpServletRequest request, HttpServletResponse response,
        Object handler, @Nullable Exception ex) throws Exception {]        
}
````

preHandle : 핸들러 어댑터 호출 전에 호출, 반환값 true인 경우만 다음으로 진행  
postHandle : 핸들러 어댑터 호출 후에 호출, 핸들러에 예외 발생시 호출되지 않음  
afterCompletion : 뷰가 렌더링 된 이후 호출, 예외가 발생해도 항상 호출, 파라미터로 받아서 로그출력가능  

<br>

## PathPattern 공식 문서  
스프링이 제공하는 url 경로는 서블릿 기술이 제공하는 경로와 다름  

````
? : 한문자 일치   
* : 경로(/) 안에서 0개 이상의 문자일치   
** : 경로 끝까지 0개 이상의 경로(/) 일치  
{spring} : 경로(/)와 일치하고 spring이라는 변수로 캡처  
{spring:[a-z]+} : [a-z]+ 와 일치하고 "spring" 경로 변수로 캡처  
{*spring} : 경로가 끝날 떄까지 0개 이상의 경로(/)와 일치하고 "spring" 변수로 캡처  
````

<br>

## 인터셉터 요청 로그
인터셉터 구현  

````java
@Slf4j
public class LogInterceptor implements HandlerInterceptor {

    public static final String LOG_ID = "logId";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String requestURI = request.getRequestURI();
        String uuid = UUID.randomUUID().toString();

        request.setAttribute(LOG_ID, uuid);

        //@RequestMapping: HandlerMethod
        //static resources: ResourceHttpRequestHandler
        if (handler instanceof HandlerMethod) {
            //호출할 컨트롤러 메서드와 모든 정보가 포함
            HandlerMethod hm = (HandlerMethod) handler;
        }

        log.info("REQUEST [{}][{}][{}]", uuid, requestURI, handler);
        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
        log.info("postHandle [{}]", modelAndView);
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        String requestURI = request.getRequestURI();
        String uuid = (String) request.getAttribute(LOG_ID);

        log.info("REQUEST [{}][{}][{}]", uuid, requestURI, handler);
        if (ex != null) {
            log.error("afterCompletion error", ex);
        }
    }
}
````

인터셉터 등록, 기존 WebConfig 클래스에 WebMvcConfigurer 상속
````java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LogInterceptor())
                .order(1)
                .addPathPatterns("/**")
                .excludePathPatterns("/css/**", "/*.ico", "/error");
    }
}
````

<br>
    
## 인터셉터 인증 체크
인증 체크는 preHandle() 함수만 있어도 가능

````java
      @Override
      public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

          String requestURI = request.getRequestURI();

          log.info("인증 체크 인터셉터 실행 {}", requestURI);

          HttpSession session = request.getSession();
          if (session == null || session.getAttribute(SessionConst.LOGIN_MEMBER) == null) {
              log.info("미인증 사용자 요청");
              response.sendRedirect("/login?redirectURL=" + requestURI);
              return false;
          }
          return true;
      }
````

서블릿 필터와는 다르게 whiteList 경로를 따로 설정하지 않고 설정단계에서 제외가능
````java
registry.addInterceptor(new LoginCheckInterceptor())
        .order(2)
        .addPathPatterns("/**")
        .excludePathPatterns("/", "/members/add", "/login", "logout", "/css/**", "/*.ico", "/error");
````

<br>

## 인터셉터 중복 호출 제거
오류 처리 후 다시 요청을 받는 경우 인터셉터 호출방지
오류페이지 관련 경로를 제외패턴에 추가

````java
.excludePathPatterns("/css/**", "/*.ico", "/error", "error-page/**");
````

<br>




