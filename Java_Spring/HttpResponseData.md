## 단순 텍스트 응답
````java
PrintWriter writer = response.getWriter();
writer.println("message-body");
````

<br>

## HTML 응답
content-type : "text/html"  
html 형식 응답이므로 content-type 지정 필수  
자바코드를 이용해 동적으로 html 작성 가능  

````java
@WebServlet(name = "responseHtmlServlet", urlPatterns = "/response-html")
public class ResponseHtmlServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        //Content-Type: text/html;charset=utf-8
        response.setContentType("text/html");
        response.setCharacterEncoding("utf-8");

        PrintWriter writer = response.getWriter();
        writer.println("<html>");
        writer.println("<body>");
        writer.println("    <div>ok</div>");
        writer.println("</body>");
        writer.println("</html>");
    }
}
````

<br>

## API 응답
json 사용시 content-type: application/json  
json 사용시 Jackson, Gson 같은 json 변환 라이브러리 추가  
json 스펙상 utf-8 형식을 사용하도록 정의되어 있으므로 charset=uft-8 필요없음  

````java
@WebServlet(name = "responseJsonServlet", urlPatterns = "/response-json")
public class ResponseJsonServlet extends HttpServlet {

    private ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        //Content-Type: application/json
        response.setContentType("application/json");
        response.setCharacterEncoding("utf-8");

        UserData userData = new UserData();
        userData.setUsername("jeonghak");
        userData.setAge(26);

        //{"username":"jeonghak", "age":"26"}
        String result = objectMapper.writeValueAsString(userData);
        response.getWriter().write(result);
    }
}
````

<br>
