## 트랜잭션
autocommit 모드를 `true`에서 `false`로 전환하는 것  

<br>

## 트랜잭션 ACID
원자성(Atomicity) : 트랜잭션 내에서 실행한 작업들은 모두 성공하거나 모두 실패  
일관성(Consistency) : 모든 트랜잭션은 일관성 있는 데이터베이스 상태를 유지(무결성 제약조건 만족)  
격리성(Isolation) : 동시에 실행되는 트랜잭션은 서로 영향을 미치지 않음  
지속성(Durability) : 트랜잭션을 성공적으로 완료하면 그 결과흫 항상 기록  

<br>
  
## 트랜잭션 격리 수준
**READ UNCOMMITED** : 커밋되지 않은 읽기  
**READ COMMITTED** : 커밋된 읽기  
**REPEATABLE READ** : 반복 가능한 읽기  
**SERIALIZABLE** : 직렬화 가능  

<br>

## DB rock - 수정
세션이 트랜잭션을 시작하고 데이터를 수정하는 동안 커밋이나 롤백 전까지 다른 세션의 데이터 수정불가  
트랜잭션은 로우의 데이터를 수정하려면 먼저 해당 로우의 락을 획득해야 수정가능  
이미 로우의 락이 사용중이면 얻기위해 일정시간 대기(SET ROCK_TIMEOUT <milliseconds>)  
트랜잭션의 데이터 수정이 완료되고 커밋 또는 롤백되면 로우의 락을 반납  

<br>

## DB rock - 조회
일반적인 데이터를 조회하는 경우 락을 획득하지 않고 바로 조회가능  
조회하는 경우 락을 획득하려면 (SELECT FOR UPDATE) 쿼리문 사용  
세션이 데이터를 조회하는 시점에 락을 획득  

<br>

## 트랜잭션 적용
1. 커넥션 유지를 위해 커넥션을 파라미터로 사용(getConnection() 호출금지)  
2. 커넥션 유지를 위해 커넥션 사용후 닫지않고 그대로 사용(close() 호출금지)  

<br>

## 트랜잭션 추상화
여러가지 기술을 사용할 수 있도록 트랜잭션 추상화 인터페이스 정의  
서비스는 더이상 특정 트랜잭션 기술을 의존하는 것이 아닌 추상화된 인터페이스를 의존  
스프링은 PlatformTransactionManager 트랜잭션 추상화 인터페이스와 각각의 구현체를 이미 정의  

    JDBC 트랜잭션 구현체 : DataSourceTransactionManager
    JPA 트랜잭션 구현체 : JpaTransactionManager
    하이버네이트 트랜잭션 구현체 : HibernateTransactionManager
    기타 트랜잭션 구현체 : EtcTransactionManager

<br>

````java
public interface TxManager {
    begin();
    commit();
    rollback();
}

public interface PlatformTransactionManager extends TransactionManager {
    TransactionStatus getTransaction(@Nullable TransactionDefinition definition)
        throws TransactionException;
    void commit(TransactionStatus status) throws TransactionException;
    void rollback(TransactionStatus status) throws TransactionException;
}
````

<br>

## 트랜잭션 동기화
트랜잭션을 유지하려면 같은 데이터베이스 커넥션을 유지해야 가능(리소스 동기화)  
트랜잭션 동기화 매니저에서 쓰레드 로컬(ThreadLocal)을 사용해서 커넥션 동기화  
멀티 쓰레드 상황에서 안전하게 커넥션 동기화 가능  
트랜잭션 동기화를 사용하려면 DataSourceUtils 사용  

````java
//트랜잭션 동기화 매니저에 관리하는 커넥션 존재하는 경우 해당 커넥션 반환, 없는 경우 생성
DataSourceUtils.getConnection(dataSource);

//동기화된 커넥션은 닫지 않고 유지, 관리하는 커넥션이 없는 경우 닫음
DataSourceUtils.releaseConnection(con, dataSource);
````

<br>

## 트랜잭션 템플릿
모든 서비스에서 트랜잭션 시작 및 종료시 비즈니스 로직을 제외한 트랜잭션 관련 코드 반복   
템플릿 콜백 패텬 활용으로 반복 문제 해결  
스프링은 트랜잭션 템플릿으로 TransactionTemplate 클래스 제공  
언체크 예외 발생시만 롤백, 체크 예외의 경우 커밋  

````java
public class TransactionTemplate {
    private PlatformTransactionManager transactionManager;
    
    //응답값이 존재하는 경우 사용
    public <T> T execute(TransactionCallback<T> action) {...}
    //응답값이 존재하지 않는 경우 사용
    void executeWithoutResult(Consumer<TransactionStatus> action) {...}
}
````

<br>
