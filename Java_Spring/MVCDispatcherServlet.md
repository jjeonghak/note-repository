## 스프링 MVC 구조비교
FrontController -&gt; DispatcherServlet  
handlerMappingMap -&gt; HandlerMapping  
MyHanlderAdapter -&gt; HandlerAdapter  
ModelView -&gt; ModelAndView  
viewResolver -&gt; ViewResolver  
MyView -&gt; View  


1. 핸들러 조회 : 핸들러 매핑을 통해 요청 URL에 매핑된 핸들러(컨트롤러) 조회  

2. 핸들러 어댑터 조회 : 핸들러를 실행할 수 있는 핸들러 어댑터 조회  

3. 핸들러 어댑터 실행 : 핸들러 어댑터 실행  

4. 핸들러 실행 : 핸들러 어댑터가 실제 핸들러 싱행  

5. ModelAndView 반환 : 핸들러 어댑터는 핸들러가 반환하는 정보를 ModelAndView 형태로 변환해서 반환  

6. viewResolver 호출 : 뷰 리졸버를 찾아 호출(JSP의 경우 InternalResourceViewResolver 자동 등록 및 사용)  

7. View 반환 : 뷰 리졸버는 뷰의 논리 이름을 물리 이름으로 변환하고 헨더링 역할을 담당하는 뷰 객체 반환(JSP의 경우 InternalResourceViewResolver(JstlView) 반환, 내부에 forward() 로직 포함)  

8. 뷰 렌더링 : 뷰를 통해서 뷰 렌더링  

<br>

## 주요 인터페이스 목록
1. 핸들러 매핑 : 'org.springframework.web.servlet.HandlerMapping'

2. 핸들러 어댑터 : 'org.springframework.web.servlet.HandlerAdapter'

3. 뷰 리졸버 : 'org.springframework.web.servlet.ViewResolver'

4. 뷰 : 'org.springframework.web.servlet.View'

<br>

## DispatcherSerlvet 구조
'org.springframework.web.servlet.DispatcherServlet'  
프론트 컨트롤러 패턴으로 구현  
부모 클래스에서 HttpServlet 상속, 서블릿으로 동작  
모든 경로(urlPatterns="/")에 대해서 매핑  
부모 클래스 FrameworkServlet에서 service() 오버라이드  
최종적으로 DispatcherServlet의 doDispatcher() 호출  
  
1. 핸들러 조회
````java
mappedHandler = getHandler(processedRequest);
if (mappedHandler == null) {
    noHandlerFound(processRequest, response);
    return;
}
````

2. 핸들러 어댑터 조회
````java
HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());
````

3. 핸들러 어댑터 및 핸들러 실행, ModelAndView 반환
````java
mv = ha.handle(processRequest, response, mappedHandler.getHandler());
processDispatcherResult(processedRequest, response, mappedHandler, mv, dispatchException);

/*
 *   private void processDispatcherResult(HttpServletResqust request, HttpServletResponse response,
 *       HandlerExcutionChain mappedHandler, ModelAndView mv, Exception exception) throws Exception {
 *
 *       //뷰 렌더링 호출
 *       render(mv, request, response);
 *       ...
 *  }
 */
````
    
4. 뷰 처리
````java
/*
 *   protected void render(ModelAndView mv, HttpServletResqust request, 
 *       HttpServletResponse response) throws Exception {
 *
 *       View view;       
 *       String viewName = mv.getViewName();
 *
 *       //뷰 리졸버를 통해 뷰 탐색 및 View 반환
 *       view = resolveViewName(viewName, mv.getModelInternal(), locale, request);
 *        
 *       //뷰 렌터링
 *       view.render(mv.getModelInternal(), request, response);
 *       ...
 *  }
 */
````
<br>
