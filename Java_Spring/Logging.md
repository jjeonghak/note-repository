## 로깅
운영 시스템에서는 시스템 콘솔을 사용하지 않고 별도의 로깅 라이브러리 사용  
스프링 부트 로깅 라이브러리(spring-boot-starter-logging) 포함  
인터페이스 : SLF4J, 구현체 : Logback  

<br>

## 로그 출력 메시지
로그 출력 포멧

    시간, 로그 레벨, 프로세스 ID, 쓰레드명, 클래스명, 로그 메시지

<br>

## 로그 레벨 순위    

     TRACE > DEBUG > INFO > WARN > ERROR

<br>

## 로그 출력 레벌 설정
````yml
#전체 로그 설정(defualt info)
logging.level.root=info

#특정 패키지와 그 하위 로그 레벨 상세 설정
logging.level.spring.springmvc=trace
````

<br>

## 로그 선언 및 호출
어노테이션 선언
````java    
@Slf4j
````

직접 선언
````java
private final Logger log = LoggerFactory.getLogger(getClass());
private static final Logger log = LoggerFactory.getLogger(Xxx.class);
````

로그 메시지 호출
````java
log.trace("trace messsage");
log.debug("debug messsage");
log.info("info messsage");
log.warn("warn messsage");
log.error("error messsage");
````

올바른 로그 스타일 : brace 형식 사용
````java
log.info("info messsage " + string);    //문자열 연산 발생, 리소스 사용
log.info("info messsage {}", string);   //파라미터를 이용해 연산 발생 안함
````

<br>
