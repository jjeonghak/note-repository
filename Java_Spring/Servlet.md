## 서버 프로세스
1. 서버 TCP/IP 대기 및 소켓 연결  
2. HTTP 요청 메시지 파싱  
3. 파싱된 정보 분석(메서드 방식, URL, 파라미터 데이터 등)  
4. 비즈니스 로직 실행  
5. HTTP 응답 메시지 생성  
6. TCP/IP 응답 전달 및 소켓 종료  

<br>

## 서블릿 
비즈니스 로직 실행을 제외한 모든 프로세스 지원  
urlPatterns의 URL 호출시 서블릿 코드 실행  
HTTP 요청 및 응답 정보를 편리하게 제공  
서블릿 컨테이너에 생성, 호출, 관리  

````java
@WebServlet(name = "servletWas", urlPatterns = "/servlet")
public class ServletWas extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse, response) {
        //애플리케이션 로직
    }
}
````

<br>

## 서블릿 요청 및 응답 흐름
1. HTTP 요청시 WAS는 Request, Response 객체를 새로 만들어 서블릿 객체 호출  
2. Request 객체의 정보를 이용해 Response 객체에 정보를 입력  
3. WAS는 Response 객체에 담겨있는 내용으로 HTTP 응답 정보를 생성  

<br>

## 서블릿 컨테이너
톰캣처럼 서블릿을 지원하는 WAS  
서블릿 컨테이너는 서블릿 객체를 생성, 초기화, 호출, 종료하는 생명주기 관리  
JSP도 서블릿으로 변환되어서 사용  
동시 요청을 위한 멀티 쓰레드 처리 지원  
서블릿 객체는 싱글톤으로 관리  

    고객 요쳥이 올때마다 계속 객체를 생성하는 것은 비효율적
    최초 로딩 시점에 서블릿 객체를 미리 생성
    모든 고객 요청은 동일한 서블릿 객체 인스턴스에 접근
    공유 변수 사용 주의 필요
    서블릿 컨테이너 종료시 서블릿 객체 소멸

<br>

## 서블릿 사용
어플리케이션 메인 메서드에 @ServletComponentScan 어노테이션 추가  
응답을 주고 받을 서블릿 클래스에 @WebServlet 어노테이션 추가  
  
````yaml
logging.level.org.apache.coyote.http11=debug //http 요청메시지 로그 확인
````

````java
@ServletComponentScan
@SpringBootApplication
public class ServletApplication {
    public static void main(String[] args) {
      SpringApplication.run(ServletApplication.class, args);
    }
}

@WebServlet(name = "basicServlet", urlPatterns = "/basic")
public class BasicServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String username = request.getParameter("username");

        response.setContentType("text/plain");
        response.setCharacterEncoding("utf-8");
        response.getWriter().write("basicServlet " + username);
    }
}
````

<br>
