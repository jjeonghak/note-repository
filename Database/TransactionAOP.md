## 트랜잭션 AOP
트랜잭션 템플릿을 사용하더라도 서비스 계층에 트랜잭션 처리 코드 필요  
스프링은 `@Transactional` 어노테이션을 이용해서 트랜잭션 처리  

<br>

## 프록시 사용
프록시 사용시 트랜잭션을 처리하는 객체와 비즈니스 로직을 처리하는 서비스 객체를 분리 가능  

````java
public class TransactionProxy {

    private MemberService target;

    public void logic() {
        TransactionStatus status = transactionManager.getTransaction(..);
        try {
            target.logic();
            transactionManager.commit(status);
        } catch (Exception e) {
            transactionManager.rollback(status);
            throw new IllegalStateException(e);
        }
    }
}

public class Service {
    public void logic() {
        //트랜잭션 관련 코드 제거, 순수 비즈니스 로직만 존재
        bizLogic(..);
    }
}
````

<br>

## 트랜잭션 AOP 적용
클래스 또는 메서드에 `@Transactional` 어노테이션 추가  
스프링에서 제공하는 기능이므로 스프링 컨테이너 및 빈 등록이 되어야 사용가능  
선언적 트랜잭션 관리 : @Transactional 어노테이션을 선언해서 관리  
프로그래밍 방식의 트랜잭션 관리 : 트랜잭션 매니저 또는 트랜잭션 템플릿 등을 사용해서 관리  

<br>

## 스프링 부트 자동 등록
개발자가 직접 등록시 스프링은 자동 등록하지 않음  
application.properties에 지정된 속성을 참고해서 데이터 소스와 트랜잭션 매니저 자동등록  

    데이터 소스 자동등록 : dataSource
    트랜잭션 매니저 자동등록 : transactionManager
    트랜잭션 매니저 구현체 자동등록 : 사용 기술에 따라 자동등록

<br>
