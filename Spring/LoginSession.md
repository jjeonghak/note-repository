## 세션
쿠키에 중요한 정보를 보관하는 방법의 보안 문제를 해결  
중요한 정보를 모두 서버에 저장  
임의의 세션 저장소를 서버에 생성  
회원 로그인시 UUID를 이용한 토큰 생성후 세션 저장소에 key-value로 매핑  
세션 key 값을 쿠키로 전달  

<br>

## 세션 직접 구현
세션 생성, 조회, 만료 기능 구현  

````java
@Component
public class SessionManager {

    //동시성 문제로 인해 ConcurrentHashMap 사용
    private Map<String, Object> sessionStore = new ConcurrentHashMap<>();
    public static final String SESSION_COOKIE_NAME = "mySessionId";

    public void createSession(Object value, HttpServletResponse response) {
        //세션 id를 생성하고 값 저장
        String sessionId = UUID.randomUUID().toString();
        sessionStore.put(sessionId, value);

        //쿠키 생성
        Cookie mySessionCookie = new Cookie(SESSION_COOKIE_NAME, sessionId);
        response.addCookie(mySessionCookie);
    }

    public Object getSession(HttpServletRequest request) {
        Cookie sessionCookie = findCookie(request, SESSION_COOKIE_NAME);
        if (sessionCookie == null) {
            return null;
        }
        return sessionStore.get(sessionCookie.getValue());
    }

    public void expire(HttpServletRequest request) {
        Cookie sessionCookie = findCookie(request, SESSION_COOKIE_NAME);
        if (sessionCookie != null) {
            sessionStore.remove(sessionCookie.getValue());
        }
    }

    public Cookie findCookie(HttpServletRequest request, String cookieName) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        return Arrays.stream(cookies)
                .filter(cookie -> cookie.getName().equals(cookieName))
                .findAny()
                .orElse(null);
    }
}
````

<br>

## HttpSession
서블릿을 통해 생성한 세션도 SessionManager와 같은 방식으로 동작  
    
    Cookie: JSESSIONID=5B78E23B513F50164D6FDD8C97B0AD05

1. 세션 생성과 조회  
````java
public HttpSession getSession(boolean create);
request.getSession(true)    // 세션 존재시 기존 세션 반환, 없으면 새로운 세션 생성
request.getSession(false)   // 세션 존재시 기존 세션 반환, 없으면 생성하지 않고 null 반환
````
    
2. 세션에 로그인 회원 정보 보관  
````java
public static final String LOGIN_MEMBER = "loginMemer";
session.setAttribute(SessionConst.LOGIN_MEMBER, loginMember());
````

3. 세션 만료
````java
HttpSession session = request.getSession(false);
if (session != null) {
    session.invalidate();
}
````

<br>

## SessionAttribute
request에서 세션을 꺼내고 세션에서 member 객체 꺼내는 과정  
세션을 생성하지 않고 찾아오는 경우 사용  
 
````java
@SessionAttribute(name = SessionConst.LOGIN_MEMBER, required = false) Member member
````

<br>

## TrackingModes
로그인을 처음 시도하면 URL이 jessionid를 포함  

````url
http://localhost:8080/;jsessionid=2090372B25BDF8567D5E116EEB96D82B
````
    
만약 웹브라우저가 쿠키를 지원하지 않는 경우 쿠키 대신 URL을 통해서 세션 유지  
세션이 유지되는 동안 모든 뷰와 링크에서 jessionid를 쿼리로 유지해야 사용가능(권장하지 않음)  

````yaml
server.servlet.session.tracking-modes=cookie
````

<br>

## 세션 타임 아웃
세션은 사용자가 로그아웃을 직접 호출해서 session.invalidate() 호출되는 경우에 삭제  
로그아웃 없이 브라우저 종료시 HTTP가 비연결성이므로 서버에서는 사용자가 브라우저를 종료한 것인지 판단 불가  
세션은 기본적으로 서버 메모리에 생성되므로 필요없는 경우 제거 필수  
사용자가 서버에 최근 요청한 시간을 기준으로 30(1800)분 정도 유지하는 대안 사용  

<br>
  
글로벌 설정[application.properties]
````yaml
server.servlet.session.timeout=1800
````
      
개별 세션 설정[.class]
````java
session.setMaxInactiveInterval(1800);

log.info("sessionId={}", session.getId());
log.info("maxInactiveInterval={}", session.getMaxInactiveInterval());
log.info("creationTime={}", new Date(session.getCreationTime()));
log.info("lastAccessedTime={}", new Date(session.getLastAccessedTime()));
log.info("isNew={}", session.isNew());
````

<br>
