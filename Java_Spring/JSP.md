## JSP
서블릿은 자바코드에서 HTML 작성  
JSP는 HTML 문서에서 자바코드를 부분부분 삽입  
뷰 생성하는 HTML 작업을 깔끔하게 가져가고 중간에 동적으로 자바코드 삽입  
코드의 상위 절반은 비즈니스 로직, 하위 절반은 뷰 HTML  
유지보수가 굉장히 어려움(MVC 패턴등장 배경)  

<br>

## JSP 라이브러리
````java
implementation 'org.apache.tomcat.embed:tomcat-embed-jasper'
implementation 'javax.servlet:jstl'
````

<br>

## JSP 문법 
jsp 문서를 뜻하는 첫줄
````html  
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
````

자바 클래스 임포트
````html
<%@ import="javax.util.List" %>
````

자바 코드 사용
````html
<% java code %>
````

자바 코드 출력
````html
<%= java code %>
````

 <br>

## members.jsp

````html
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="spring.servlet.domain.member.Member" %>
<%@ page import="spring.servlet.domain.member.MemberRepository" %>
<%@ page import="java.util.List" %>

<%
    MemberRepository memberRepository = MemberRepository.getInstance();
    List<Member> members = memberRepository.findAll();
%>

<html>
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<a href="/index.html">main</a>
<table>
    <thead>
        <th>id</th>
        <th>username</th>
        <th>age</th>
    </thead>
    <tbody>
    <%
        for (Member member : members) {
            out.write("     <tr>\n");
            out.write("         <td>" + member.getId() + "</td>\n");
            out.write("         <td>" + member.getUsername() + "</td>\n");
            out.write("         <td>" + member.getAge() + "</td>\n");
            out.write("     </tr>\n");
        }
    %>
    </tbody>
</table>
</body>
</html>
````

<br>

