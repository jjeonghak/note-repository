## ArgumentResolver
로그인된 사용자를 @SessionAttribute 어노테이션이 아닌 @Login 어노테이션 사용  
````java
@GetMapping("/")
public String homeLoginV3ArgumentResolver(@Login Member loginMember, Model model) {

    if (loginMember == null) {
        return "home";
    }

    model.addAttribute("member", loginMember);
    return "loginHome";
}
````

<br>

## @Login 어노테이션 생성
@Target 어노테이션 : 파라미터에만 사용  
@Retention 어노테이션 : 리플렉션 등을 활용할 수 있도록 런타임까지 어노테이션 정보가 남아있음  
````java
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface Login {
}
````

<br>

## 구현 및 등록
@Login 어노테이션 구현  
````java
@Slf4j
public class LoginMemberArgumentResolver implements HandlerMethodArgumentResolver {
    //@Login 어노테이션이 있으면서 Member 타입이면 해당 ArgumentResolver 사용
    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        log.info("supportsParameter 실행");

        boolean hasLoginAnnotation = parameter.hasParameterAnnotation(Login.class);
        boolean hasMemberType = Member.class.isAssignableFrom(parameter.getParameterType());
        return hasLoginAnnotation && hasMemberType;
    }
    //컨트롤러 호출 직전에 호출되어서 필요한 파라미터 정보를 생성
    @Override
    public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer, NativeWebRequest webRequest, WebDataBinderFactory binderFactory) throws Exception {
        log.info("resolveArgument 실행");

        HttpServletRequest request = (HttpServletRequest) webRequest.getNativeRequest();
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        return session.getAttribute(SessionConst.LOGIN_MEMBER);
    }
}
````

<br>

### argumentResolver 등록
````java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(new LoginMemberArgumentResolver());
    }
}
````

<br>
