## 프론트 컨트롤러 패턴
프론트 컨트롤러 서블릿 하나로 클라이언트의 요청을 받음  
프론트 컨트롤러가 요청에 맞는 컨트롤러를 찾아서 호출  
공통 처리 기능 지원  
프론트 컨트롤러를 제외한 나머지 컨트롤러는 서블릿을 사용하지 않아도 상관없음  
이후 스프링 웹 MVC의 DispatcherServlet이 FrontController 패턴으로 구현  

<br>

## FrontControllerV1 
1. URL 매핑 정보에서 컨트롤러 조회  
2. 컨트롤러 호출  
3. 컨트롤러에서 JSP forward  

<br>

### 컨트롤러 인터페이스(서블릿 미사용)
````java
public interface ControllerV1 {
    void process(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException;
}
````

<br>

### 프론트 컨트롤러
````java
@WebServlet(name = "frontControllerServletV1", urlPatterns = "/front-controller/v1/*")
public class FrontControllerServletV1 extends HttpServlet {

    private Map<String, ControllerV1> controllerMap = new HashMap<>();

    public FrontControllerServletV1() {
        controllerMap.put("/front-controller/v1/members/new-form", new MemberFormControllerV1());
        controllerMap.put("/front-controller/v1/members/save", new MemberSaveControllerV1());
        controllerMap.put("/front-controller/v1/members", new MemberListControllerV1());
    }

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String requestURI = request.getRequestURI();
        ControllerV1 controller = controllerMap.get(requestURI);
        
        //잘못된 url, 404 not found
        if (controller == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        
        controller.process(request, response);
    }
}
````

<br>

## FrontControllerV2(뷰 이동 중복 제거)
1. URL 매핑 정보에서 컨트롤러 조회  
2. 컨트롤러 호출  
3. MyView 반환  
4. render() 호출  
5. JSP forward  

<br>

### 뷰 클래스
````java
public class MyView {
    private String viewPath;

    public MyView(String viewPath) {
        this.viewPath = viewPath;
    }

    public void render(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        RequestDispatcher dispatcher = request.getRequestDispatcher(viewPath);
        dispatcher.forward(request, response);
    }
}
````

<br>

### 프론트 컨트롤러
````java
@WebServlet(name = "frontControllerServletV2", urlPatterns = "/front-controller/v2/*")
public class FrontControllerServletV2 extends HttpServlet {

    private Map<String, ControllerV2> controllerMap = new HashMap<>();

    public FrontControllerServletV2() {
        controllerMap.put("/front-controller/v2/members/new-form", new MemberFormControllerV2());
        controllerMap.put("/front-controller/v2/members/save", new MemberSaveControllerV2());
        controllerMap.put("/front-controller/v2/members", new MemberListControllerV2());
    }

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String requestURI = request.getRequestURI();
        ControllerV2 controller = controllerMap.get(requestURI);
        if (controller == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        MyView view = controller.process(request, response);
        view.render(request, response);
    }
}
````

<br>

## FrontControllerV3(서블릿 종속성 제거, 뷰 이름 중복 제거)
1. 컨트롤러 조회  
2. 컨트롤러 호출  
3. ModelView 반환  
4. viewResolver 호출  
5. MyView 반환  
6. render(model) 호출  

<br>

### 모델뷰 클래스
````java
@Getter @Setter
public class ModelView {
    private String viewName;
    private Map<String, Object> model = new HashMap<>();

    public ModelView(String viewName) {
        this.viewName = viewName;
    }
}
````

<br>

### 뷰 클래스
````java
public class MyView {
    private String viewPath;

    public MyView(String viewPath) {
        this.viewPath = viewPath;
    }

    public void render(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        RequestDispatcher dispatcher = request.getRequestDispatcher(viewPath);
        dispatcher.forward(request, response);
    }

    public void render(Map<String, Object> model, HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        modelToRequestAttribute(model, request);
        RequestDispatcher dispatcher = request.getRequestDispatcher(viewPath);
        dispatcher.forward(request, response);
    }

    private void modelToRequestAttribute(Map<String, Object> model, HttpServletRequest request) {
        model.forEach((k, v) -> request.setAttribute(k, v));
    }
}
````

<br>

### 프론트 컨트롤러
````java
@WebServlet(name = "frontControllerServletV3", urlPatterns = "/front-controller/v3/*")
public class FrontControllerServletV3 extends HttpServlet {

    private Map<String, ControllerV3> controllerMap = new HashMap<>();

    public FrontControllerServletV3() {
        controllerMap.put("/front-controller/v3/members/new-form", new MemberFormControllerV3());
        controllerMap.put("/front-controller/v3/members/save", new MemberSaveControllerV3());
        controllerMap.put("/front-controller/v3/members", new MemberListControllerV3());
    }

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String requestURI = request.getRequestURI();
        ControllerV3 controller = controllerMap.get(requestURI);
        if (controller == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        Map<String, String> paramMap = createParamMap(request);
        ModelView mv = controller.process(paramMap);

        String viewName = mv.getViewName();
        MyView view = viewResolver(viewName);
        view.render(mv.getModel(), request, response);
    }

    private MyView viewResolver(String viewName) {
        return new MyView("/WEB-INF/views/" + viewName + ".jsp");
    }

    private Map<String, String> createParamMap(HttpServletRequest request) {
        Map<String, String> paramMap = new HashMap<>();
        request.getParameterNames().asIterator()
                        .forEachRemaining(paramName -> paramMap.put(paramName, request.getParameter(paramName)));
        return paramMap;
    }
}
````

<br>

## FrontControllerV4(V3와 구조는 동일하지만 model을 파라미터로 넘기며 ViewName 반환)
1. 컨트롤러 조회  
2. 컨트롤러 호출  
3. ViewName 반환  
4. viewResolver 호출  
5. MyView 반환  
6. render(model) 호출  

<br>

````java
@Override
protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    String requestURI = request.getRequestURI();
    ControllerV4 controller = controllerMap.get(requestURI);
    if (controller == null) {
        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        return;
    }

    Map<String, String> paramMap = createParamMap(request);
    Map<String, Object> model = new HashMap<>();
    
    String viewName = controller.process(paramMap, model);

    MyView view = viewResolver(viewName);
    view.render(model, request, response);
}
````

<br>
