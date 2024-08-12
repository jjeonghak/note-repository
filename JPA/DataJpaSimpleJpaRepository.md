## JpaRepository 구현체
@Repository 어노테이션 적용으로 JAPA 예외를 스프링 예외로 변환  
@Transactional 어노테이션 적용  

    서비스계층에서 트랜잭션 없어도 레포지토리에서 트랜잭션 시작
    서비스계층에서 트랜잭션 시작시 전파 받아서 사용

````java
@Repository
@Transactional(readOnly = true)
public class SimpleJpaRepository<T, ID> implements JpaRepositoryImplementation<T, ID> {
    @Transactional
    @Override
    public <S extends T> S save(S entity) {

        Assert.notNull(entity, "Entity must not be null.");

        if (entityInformation.isNew(entity)) {
          em.persist(entity);
          return entity;
        } else {
          return em.merge(entity);
        }
    }
    
    ...
}
````

<br>

## isNew()
save 메서드는 isNew 메서드를 통해서 새로운 객체인지 기존 객체인지 판별  
@GenerateValue 적용이 아닌 사용자 지정 pk인 경우 기본적으로 merge 메서드 호출됨  

    식별자가 객체일 경우 null 판단
    식별자가 자바 기본타입인 경우 0 판단
    Persistable 인터페이스 상속 후 isNew 메서드 오버라이딩(사용자 지정 pk인 경우, 타입 T)

````java
public class Class implements Persistable<T> {
    @Override
    public boolean isNew() {
        return createDate == null;
    }
}
````

<br>

