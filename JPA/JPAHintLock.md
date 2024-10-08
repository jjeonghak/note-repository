## JPA Hint
JPA 쿼리 힌트(sql 힌트가 아닌 jpa 구현체에게 제공하는 힌트)  

````java
//readOnly 옵션은 변경감지를 위한 스냅샷을 생성하지 않으므로 변경감지 발생안함
@QueryHints(value = @QueryHint(name = "org.hibernate.readOnly", value = "true"))
Member findReadOnlyByUsername(String username);
````

<br>

## JPA 낙관적 잠금(Optimistic Lock)
트랜잭션끼리의 충동이 발생하지 않을 것을 가정하고 락을 거는 방법  
동시에 동일한 데이터에 대한 여러 업데이트가 서로 간섭하지 않도록 방지하는 version 속성 확인하여 변경감지  
@Version 어노테이션 사용시 각 엔티티 클래스에 하나씩 정수타입에 명시  

<br>

## JPA 비관적 잠금(Pessimistic Lock)
선점 잠금
트랜잭션끼리의 충동이 발생할 것을 가정하고 우선 락을 거는 방법

    PESSIMISTIC_WRITE : 다른 트랜잭션에서 읽기, 쓰기 불가
    PESSIMISTIC_READ : 다른 트랜잭션에서 읽기는 가능
    PESSIMISTIC_FORCE_INCREMENT :version 정보를 증가시키는 비관적 락

````java
@Lock(value = LockModeType.PESSIMISTIC_WRITE)
List<Member> findLockByUsername(String username);
````

<br>
