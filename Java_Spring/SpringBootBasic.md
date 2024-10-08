## 주요 라이브러리
````
spring-boot-starter-web
	spring-boot-starter-tomcat : 웹 서버
	spring-webmvc : 웹 모델뷰컨트롤러

spring-boot-starter-thymeleaf : 타임리프 템플릿 엔진(view)

spring-boot-starter : spring-boot + spring core + logging
	spring-boot
		spring-core
	spring-boot-starter-logging
		logback
		slf4j
````

<br>

## 테스트 라이브러리
````
spring-boot-starter-test
	junit : 자바 주요 테스트 프레임워크
	mockito : 목 라이브러리
	assertj : 테스트 코드 작성 라이브러리
	spring-test : 스프링 통합 테스트 지원
````

<br>

## welcome page
src/main/resources/static/index.html 탐색 후 html 형식의 화면 출력

<br>

## template engines
1. FreeMarker  
2. Groovy  
3. Thymeleaf  
4. Mustache  

<br>

## @GetMapping
사용자가 get 방식으로 접근할 경우 그에 맞는 뷰를 매핑해서 처리  
컨트롤러에서 리턴 값으로 문자를 반환하면 뷰리졸버가 화면을 찾아서 처리  
'resources:templates/' + {viewName} + 'html'  
spring-boot-devtools 라이브러리 추가하면, 서버 재시작 없이 html 파일을 컴파일만으로 view 파일 변경 가능   

<br>

## 터미널에서 빌드
1. terminal  
2. ./gradlew build  
3. cd build/libs  
4. java -jar projectName-spring-0.0.1-SNAPSHOT.jar  
5. 실행  
6. 실행 종료    
7. ./gradlew clean  //build 폴더 삭제  

<br>

### 정적 컨텐츠
파일을 그대로 웹 브라우저에 전송

### MVC와 템플릿 엔진
서버에서 html 파일 변경을 한 후 웹 브라우저에 전송

<br>

## API
@ResponseBody 어노테이션 존재시 viewResolver가 아닌 HttpMessageConverter 동작  

HttpMessageConverter : 문자 반환인 경우 StringHttpMessageConverter, 객체 반환인 경우 MappingJackson2HttpMessageConverter 동작  

클라이언트의 HTTP Accept 헤더와 서버의 컨트롤러 반환 타입 정보를 조합해서 HttpMessageConverter가 선택된다  

<br>

## 일반적인 웹 애플리케이션 계층 구조  
컨트롤러 : 웹 MVC의 컨트롤러 역할  
서비스  : 핵심 비지니스 로직 구현  
레포지토리 : 데이터베이스에 접근, 도메인 객체를 DB에 저장하고 관리  
도메인 : 비지니스 도메인 객체  

<br>

## 스프링 빈 등록방법
주로 정형화된 컨트롤러, 서비스, 레포지토리 같은 코드는 컴포넌트 스캔을 사용  
정형화되지 않고 상황에 따라 구현 클래스를 변경해야하는 경우는 자바 코드 직접 구현  

1. 컴포넌트 스캔(@Component)과 자동 의존관계 설정(@Controller, @Service, @Repository)  

2. 자바 코드 직접 구현  

 		SpringConfig 클래스에 @Configuration 어노테이션
		@Bean 어노테이션과 각각의 싱글톤 생성자 구현
		하지만 Controller는 무조건 컴포넌트 스캔으로 구현

<br>

## 스프링 빈과 의존관계
스프링은 스프링 컨테이너에 스프링 빈을 등록할 때, 기본으로 싱글톤으로 등록한다(전역변수)  
따라서 같은 스프링 빈이면 모두 같은 인스턴스  

<br>

## DI(dependnecy injection) : 의존성 주입
의존관계는 동적으로 변하는 경우는 극히 드물어 동적으로 변경해야하는 경우는 없다  
그러므로 실행할때 한번 의존관계를 설정해놓고 다시 호출되지 않으므로 생성자 주입방식 추천  

1. 필드 주입 : 선언과 동시에 삽입, 수정 불가한 가장 비효율적인 방식
````java
@Autowired private MemberService memberService;
````

2. 세터 주입 : 접근제한자가 public이므로 외부에 노출  
````java
@Autowired
public void serMemberService(MemberService memberService) {
	this.memberService = memberService;
}
````

3. 생성자 주입 : 가장 효율적이며 많이 사용
````java
@Autowired
public MemberController(MemberService memberService) {
	this.memberService = memberService;
}
````

<br>

## 스프링 DB 접근 기술
````
h2 downroad
h2/bin/h2.sh chmod 775 실행
ip -> localhost로 변경
test.mv.db 생긴것 확인
URL jdbc:h2:tcp://localhost/~/test 소켓으로 접근
````

<br>

## 순수 Jdbc

build.gradle 라이브러리 추가
````java
implementation 'org.springframework.boot:spring-boot-starter-test'
runtimeOnly 'com.h2database:h2'
````

resources/application.properties 소켓, 드라이버 연결
````yaml
spring.datasource.url=jdbc:h2:tcp://localhost/~/test
spring.datasource.driver-class-name=org.h2.Driver
````

<br>

## 개방-폐쇄 원칙(OCP, open-closed principle)
확장에는 열려있고 수정 및 변경에는 닫혀있다.  
인터페이스 객체(구현체)를 변경하면서도 나머지 코드는 건들이지 않고 실행가능  

<br>

## 통합 테스트
@SpringBootTest : 스프링 컨테이너와 테스트를 함께 실행  
@Transactional : 테스트 케이스에 붙은 어노테이션은 테스트 시작전에 트랜잭션을 시작하고 테스트 완료 후에 롤백  

<br>

## 스프링 JdbcTemplate
순수 Jdbc 설정과 같이 설정  
JDBC API에서 본 반복코드를 대부분 제거  
sql은 직접 작성  

<br>
