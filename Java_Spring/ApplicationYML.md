## application.yml
설정 정보가 많다면 application.property 파일보다 추천  
스프링 데이터베이스 설정 및 로그 설정  
main과 test에 각각 하나씩 생성가능(각 디렉토리의 yml 파일이 우선순위 높음)  

<br>


````yml
spring:
  datasource:
    url: jdbc:h2:tcp://localhost/~/jpashop;
#        jdbc:h2:mem:test (메모리 모드 사용)
    username: sa
    password:
      driver-class-name: org.h2.Driver

  jpa:
    hibernate:
      ddl-auto: create
    properties:
      hibernate:
#        show_sql: true  
        format_sql: true
  
  output:
    ansi:
      enabled: ALWAYS
      

logging:
  level:
    org.hibernate.SQL: debug   #디버그 모드로 쿼리문 로그 출력
    org.hibernate.type: trace  #쿼리 파라미터 출력(?에 들어가는 실제값)
    #외부 라이브러리 사용(p6spy)으로 좀더 깔끔하게 조회가능
   

spring.messages.basename=messages,errors
server.servlet.session.tracking-modes=cookie
server.servlet.session.timeout=1800

````

<br>
