## 컨트롤러 인터페이스
과거 버전 : 'org.springframework.web.servlet.mvc.Controller'  
@Controller 어노테이션과는 전혀 다름  

<br>

## 컨트롤러 호출
핸들러 매핑 : 핸들러 매핑에서 컨트롤러를 찾을 수 있어야 호출 가능(스프링 빈 이름으로)  
핸들러 어댑터 : 핸들러 매핑을 통해서 찾은 핸들러를 실행할 수 있는 핸들러 어댑터 필요  

<br>

## HandlerMapping
````
priority
0 = RequestMappingHandlerMapping    //어노테이션 기반 컨트롤러인 @RequestMapping에서 사용
1 = BeanNameUrlHandlerMapping       //스프링 빈의 이름으로 핸들러 탐색
...
````

<br>

## HandlerAdapter
````
priority
0 = RequestMappingHandlerMapping    //어노테이션 기반 컨트롤러인 @RequestMapping에서 사용
1 = HttpRequestHandlerAdapter       //HttpRequestHandler 처리
2 = SimpleControllerHandlerAdapter  //Controller 인터페이스(과거 버전) 처리
...
````

<br>


