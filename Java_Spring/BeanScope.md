## 빈 스코프
싱글톤 스코프 : 기본 스코프, 스프링 컨테이너의 시작과 종료까지 유지되는 가장 넓은 범위의 스코프  
````java
@Bean("singleton")
````
프로토타입 스코프 : 스프링 컨테이너는 프로토타입 빈의 생성과 의존관계주입까지만 관여  
````java
@Bean("prototype")
````
웹 스코프  

      request : 웹 요청이 들어오고 나갈때까지 유지
      session : 웹 세션이 생성되고 종료될때까지 유지
      application : 웹의 서블릿 컨텍스와 같은 범위로 유지

<br>

## 프로토타입 스코프
기본적으로 스프링 컨테이너는 의존관계 주입까지만 관여하고 이후부터 클라이언트가 관리  
@PreDestroy 종료 메서드 자동 호출 안됨(필요시 클라이언트가 직접 호출)  
  
1. 프로토타입 스코프의 빈을 스프링 컨테이너에 요청  
2. 스프링 컨테이너는 이 시점에 프로토타입 빈을 생성하고, 필요한 의존관계 주입  
3. 스프링 컨테이너는 생성한 프로토타입 빈을 클라이언트에 반환  
4. 이후에 스프링 컨테이너에 같은 요청이 오면 항상 새로운 프로토타입 빈을 생성해서 반환  

<br>

## 싱글톤 빈에 프로토타입 스코프 
기본적으로 컨테이너에 의해서 싱글톤 빈이 생성될 때 프로토타입 스코프 빈도 의존관계 주입을 받아생성  
한번 의존관계 주입을 받은 프로토타입 빈은 싱글톤 빈이 사라지기 전까지 계속 존재하므로 싱글톤 빈과 같이 동작  
  
ObjectFactory, ObjectProvider 사용으로 프로토타입 원래 목적에 맞게 사용가능  
ObjectFactory는 ObjectProvider보다 상위 인터페이스  

````java
//컨테이너에게 호출될 때마다 마땅한 빈 요청
private ObjectProvider<PrototypeBean> prototypeBeanProvider;
private ObjectFactory<PrototypeBean> prototypeBeanFactory;

//컨테이너에게 프로토타입 빈을 필요할 때마다 탐색 요청
PrototypeBean prototypeBean = prototypeBeanProvider.getObject();
PrototypeBean prototypeBean = prototypeBeanFactory.getObject();
````

<br>

## 웹 라이브러리 추가
````java
implementation 'org.springframework.boot:spring-boot-starter-web'
````
스프링 부트는 내장 톰켓 서버를 활용해서 웹 서버와 스프링을 함께 실행  
웹 라이브러리 없는 경우 AnnotationConfigApplicationContext 기반 애플리케이션 구동  
있는 경우 AnnotationConfigServletWebServerApplicationContext 기반 애플리케이션 구동  
만약 기본 포트인 8080 포트 사용중이라면 포트 설정(main/resources/application.properties)  
````yml
server.port=9090
````

<br>

## 웹 스코프
웹 환경에서만 동작  
스프링 컨테이너가 종료시점까지 관리  
종료 메서드 자동호출  

	request : HTTP 요청 하나가 들어오고 나갈때까지 유지
		각각의 요펑마다 별도의 인스턴스 생성 및 관리
        	UUID 사용해서 HTTP 요청 구분
	공통 포멧 : [UUID][requestURL]{message}
	session : HTTP session과 동일한 생명주기
	application : 서블릿 컨텍스트(ServletContext)와 동일한 생명주기
	websocket : 웹 소켓과 동일한 생명주기

<br>
