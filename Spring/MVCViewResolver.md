## 뷰 리졸버
스프링 부트는 InternalResolverViewResolver 자동 등록  
설정정보를 이용해서 논리적 이름을 파라미터로 물리적 이름 생성  

````yaml  
spring.mvc.view.prefix=/WEB-INF/views/
spring.mvc.view.suffix=.jsp
````

````java
@Bean
ViewResolver internalResourceViewResolver() {
    return new InternalResourceViewResolver(prefix:"/WEB-INF/views/", suffix:".jsp");
}
````

<br>

## ViewResolver
````
priority
...
1 = BeanNameViewResolver          //빈 이름으로 뷰 탐색 및 반환
2 = InternalResourceViewResolver  //JSP 처리가능한 뷰 반환
...
````

<br>
