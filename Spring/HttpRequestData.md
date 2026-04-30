## GET query param  

````java
@WebServlet(name = "requestParamServlet", urlPatterns = "/request-param")
public class RequestParamServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        System.out.println("--- ALl Param - start ---");
        request.getParameterNames().asIterator()
                .forEachRemaining(paramName -> System.out.println(paramName + ": " + request.getParameter(paramName)));
        System.out.println("--- All Param - end ---");
        System.out.println();

        System.out.println("--- Single Param - start ---");
        String username = request.getParameter("username");
        System.out.println("username: " + username);
        String age = request.getParameter("age");
        System.out.println("age: " + age);
        System.out.println("--- Single Param - end ---");
        System.out.println();

        System.out.println("--- Same Params - start ---");
        String[] usernames = request.getParameterValues("username");
        for (String s : usernames) {
            System.out.println("username: " + s);
        }
        System.out.println("--- Same Params - end ---");
        System.out.println();

        response.getWriter().write("ok");
    }
}
````

<br>

## POST HTML form
content-type : application/x-www-form-urlencoded  
바디에 데이터가 들어있으므로 content-type 지정 필수  
메시지 바디에 쿼리 파라미터 형식으로 데이터 전달  

````html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<form action="/request-param" method="post">
    username <input type="text" name="username" />
    age <input type="text" name="age" />
    <button type="submit">전송</button>
</form>
</body>
</html>
````

<br>

## API
HTTP 메시지 바디에 데이터를 직접 담아 요청(주로 json)  
json 사용시 content-type: application/json  
json 사용시 Jackson, Gson 같은 json 변환 라이브러리 추가  
POST, PUT, PATCH 사용  

<br>

### string
````java
@WebServlet(name = "requestBodyStringServlet", urlPatterns = "/request-body-string")
public class RequestBodyStringServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        //바디 정보를 바이트코드로
        ServletInputStream inputStream = request.getInputStream();
        //바이트코드 -> 문자열
        String messageBody = StreamUtils.copyToString(inputStream, StandardCharsets.UTF_8);
        System.out.println("messageBody: " + messageBody);
        response.getWriter().write("ok");
    }
}
````

<br>

### json
````java
@WebServlet(name = "requestBodyJsonServlet", urlPatterns = "/request-body-json")
public class RequestBodyJsonServlet extends HttpServlet{

    //Jackson 라이브러리
    private ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        ServletInputStream inputStream = request.getInputStream();
        String messageBody = StreamUtils.copyToString(inputStream, StandardCharsets.UTF_8);

        UserData userData = objectMapper.readValue(messageBody, UserData.class);
        System.out.println("userData.getUsername() = " + userData.getUsername());
        System.out.println("userData.getAge() = " + userData.getAge());

        response.getWriter().write("ok");
    }
}
````

<br>
