## MVC 패턴 개요
하나의 서블릿이나 JSP만으로 비즈니스 로직과 뷰 렌더링까지 모두 처리하게 되면 너무 많은 역할을 수행  
유지보수가 어려우며 비즈니스 로직과 뷰 변경 발생시 해당 파일 수정 필요  
변경 라이프 사이클이 다르므로 분리해서 관리할 필요성 발생  
서블릿은 자바코드에, JSP는 뷰 렌더링에 특화  

````
컨트롤러 : HTTP 요청을 받아서 파라미터를 검증, 비즈니스 로직 실행, 뷰에 전달할 결과 데이터 모델에 주입
모델 : 뷰에 출력할 데이터 보관
뷰 : 모델에 담겨있는 데이터를 이용해서 화면 생성, HTML 생성
````

<br>

## MVC 패턴 적용
서블릿을 컨트롤러로, JSP를 뷰로 사용  
````
/WEB-INF : 이 경로안에 JSP가 존재하면 외부(클라이언트 경로 접근)에서 직접 호출 불가
redirect : 실제 클라이언트에 응답이 나갔다가 리다이렉트 경로로 다시 요청(클라이언트 인지, url 변경)
forward : 서버 내부에서 일어나는 호출(클라이언트 인지불가)
````

<br>

````java
@WebServlet(name = "mvcMemberFormServlet", urlPatterns = "/servlet-mvc/members/new-form")
public class MvcMemberFormServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        //WEB-INF 이 경로안에 JSP가 존재하면 외부(클라이언트 경로 접근)에서 직접 호출 불가
        String viewPath = "/WEB-INF/views/new-form.jsp";
        RequestDispatcher dispatcher = request.getRequestDispatcher(viewPath);
        //다른 서블릿이나 JSP로 이동, 서버 내부에서 다시 호출(리다이렉트 아님)
        dispatcher.forward(request, response);
    }
}

@WebServlet(name = "mvcMemberSaveServlet", urlPatterns = "/servlet-mvc/members/save")
public class MvcMemberSaveServlet extends HttpServlet {

    private static MemberRepository memberRepository = MemberRepository.getInstance();

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String username = request.getParameter("username");
        int age = Integer.parseInt(request.getParameter("age"));

        Member member = new Member(username, age);
        memberRepository.save(member);

        //Model 데이터 주입
        request.setAttribute("member", member);

        String viewPath = "/WEB-INF/views/save-result.jsp";
        RequestDispatcher dispatcher = request.getRequestDispatcher(viewPath);
        dispatcher.forward(request, response);
    }
}
````

<br>

## MVC 패턴 한계
포워드 중복, view 이동하는 코드가 항상 중복되어 호출  
사용하지 않는 경우가 많은 response  
공통처리가 어려움(프론트 컨트롤러 패턴 도입)  

<br>
