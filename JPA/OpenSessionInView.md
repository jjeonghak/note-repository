## OSIV
하이버네이트 : Open Session In View  
JPA : Open EntityManager In View  

<br>

## OSIV ON
spring.jpa.open-in-view: true(default)  
애플리케이션 실행시 경고로그(warn : spring.jpa.open-in-view is enabled by default)  
트랜잭션 시작 시점부터 API 응답이 끝날 때까지 영속성 컨텍스트와 데이터베이스 커넥션 유지  
지연 로딩은 영속성 컨텍스트가 존재해야하며 영속성 컨텍스트는 데이터베이스 커넥션을 유지  
오랜 시간 데이터베이스 커텍션 리소스를 사용, 실시간 트래픽이 중요한 경우 장애발생(커넥션 마름)  

<br>

## OSIV OFF
spring.jpa.open-in-view: false  
트랜잭션 종료시 영속성 컨텍스트 소멸 및 데이터베이스 커넥션 반환  
모든 지연로딩을 트랜잭션 범위에서 처리필수(view template에서 지연로딩 작동안함)  
트랜잭션 종료 후 지연로딩시 LazyInitializationException 발생  

<br>

## 커멘드와 쿼리 분리
OSIV OFF 상태로 커맨드와 쿼리를 분리해서 복잡성 관리  

OrderService : 핵심 비즈니스 로직  
OrderQueryService : 화면이나 API에 맞춘 서비스(주로 읽기 전용 트랜잭션 사용)  

<br>
