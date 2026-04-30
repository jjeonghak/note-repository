## 공통 관심사(cross-cutting concern)
로그인하지 않은 사용잗도 직접 url을 입력하면 해당 페이지에 접근가능  
등록, 수정, 삭제, 조회 등등 여러 로직에서 공통으로 인증에 대해 관심을 가짐  
스프링 AOP 도입으로 해결가능하나 웹의 공통 관심사는 서블릿 필터 또는 스프링 인터셉터를 사용  

<br>

## 서블릿 필터
필터 인터페이스를 구현하고 등록하면 서블릿 컨테이너가 필터를 싱글톤 객체로 생성하고 관리

````java
public interface Filter {
    //필터 초기화 메서드, 서블릿 컨테이너가 생성될 때 호출
    public default void init(FilterConfig filterConfig) throws Servlet#Exception {}
    
    //고객의 요청이 올 때마다 해당 메서드가 호출
    public void doFilter(ServletRequest request, ServletResponse response, 
            FilterChain chain) throws IOException, ServletException;
    
    //필터 종료 메서드, 서블릿 컨테이너가 종료될 때 호출
    public default void destroy() {}
}
````

<br>

1. 필터 흐름  
    HTTP 요청 -&gt; WAS -&gt; 필터 -&gt; 서블릿 -&gt; 컨트롤러  
    모든 요청에 필터 적용시 '/*' url을 적용  
    스프링을 사용하는 경우 서블릿은 디스패처 서블릿  
  
2. 필터 제한  
    로그인 사용자 : HTTP 요청 -&gt; WAS -&gt; 필터 -&gt; 서블릿 -&gt; 컨트롤러   
    비로그인 사용자 : HTTP 요청 -&gt; WAS -&gt; 필터(적절하지 않은 요청처리, 서블릿 호출 안함)  

3. 필터 체인  
    HTTP 요청 -&gt; WAS -&gt; 필터1 -&gt; 필터2 -&gt; 필터3 -&gt; 서블릿 -&gt; 컨트롤러  
    필터는 체인으로 구성, 자유롭게 추가 및 제거 가능  
    다음 필터 호출시 request, response 객체를 다른 객체로 변경가능(스프링 인터셉터는 불가)  

<br>
    
## 로그필터 구현 및 등록
실무에서 HTTP 요청시 같은 요청의 로그에 모두 같은 식별자를 자동으로 남기는 방법은 logback mdc  
필터 구현(모든 요청에 대한 로그)  

````java
@Slf4j
public class LogFilter implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        log.info("log filter init");
    }

    @Override
    public void destroy() {
        log.info("log filter destroy");
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        log.info("log filter doFilter");
        
        //다운 캐스팅
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String requestURI = httpRequest.getRequestURI();
        String uuid = UUID.randomUUID().toString();

        try {
            log.info("REQUEST [{}][{}]", uuid, requestURI);
            //다음 필터를 체인형식으로 호출
            chain.doFilter(request, response);
        } catch (Exception e) {
            throw e;
        } finally {
            log.info("RESPONSE [{}][{}]", uuid, requestURI);
        }
    }
}
````

<br>

### 필터 등록
````java
@ServletComponentScan, @WebFilter(filterName = "logFilter", urlPatterns = "/*")로 지정가능하나 순서 지정불가
@Configuration
public class WebConfig {
    @Bean
    public FilterRegistrationBean logFilter() {
        FilterRegistrationBean<Filter> filterFilterRegistrationBean = new FilterRegistrationBean<>();
        
        //등록할 필터 지정
        filterFilterRegistrationBean.setFilter(new LogFilter());
        
        //체인 순서, 낮을 수록 먼저 동작
        filterFilterRegistrationBean.setOrder(1);
        
        //필터를 적용할 url 패턴 지정
        filterFilterRegistrationBean.addUrlPatterns("/*");
        return filterFilterRegistrationBean;
    }
}
````

<br>

### 인증 체크 필터
````java
@Slf4j
public class LoginCheckFilter implements Filter {

    private static final String[] whitelist = {"/", "/member/add", "/login", "/logout", "/css/*"};

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String requestURI = httpRequest.getRequestURI();
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        try {
            log.info("인증 체크 필터 시작 {}", requestURI);
            if (isLoginCheckPath(requestURI)) {
                log.info("인증 체크 로직 실행 {}", requestURI);
                HttpSession session = httpRequest.getSession(false);
                if (session == null || session.getAttribute(SessionConst.LOGIN_MEMBER) == null) {
                    log.info("미인증 사용자 요청 {}", requestURI);
                    httpResponse.sendRedirect("/login?redirectURL=" + requestURI);
                    return;
                }
            }
            chain.doFilter(request, response);
        } catch (Exception e) {
            throw e;
        } finally {
            log.info("인증 체크 필터 종료 {}", requestURI);
        }
    }

    /**
     * whitelist 인증 체크 제외
     */
    private boolean isLoginCheckPath(String requestURI) {
        return !PatternMatchUtils.simpleMatch(whitelist, requestURI);
    }
}

@PostMapping("/login")
public String loginV4(@Validated @ModelAttribute LoginForm form, BindingResult bindingResult,
                      @RequestParam(defaultValue = "/") String redirectURL, HttpServletRequest request) {
    if (bindingResult.hasErrors()) {
        return "login/loginForm";
    }

    Member loginMember = loginService.login(form.getLoginId(), form.getPassword());
    if (loginMember == null) {
        bindingResult.reject("loginFail", "아이디 또는 비밀번호가 맞지 않습니다.");
        return "login/loginForm";
    }

    //로그인 성공처리
    HttpSession session = request.getSession(true);
    session.setAttribute(SessionConst.LOGIN_MEMBER, loginMember);
    //필터에서 쿼리파라미터로 리다이렉트 url 전달
    return "redirect:" + redirectURL;
}
````

