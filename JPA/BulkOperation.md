## 벌크 연산
쿼리 한번으로 여러 테이블 로우변경  
이전 sql 저장소에 있던 쿼리문 자동 플러시  
update, delete 지원  
영속성 컨텍스트를 무시하고 데이터베이스에 직접 쿼리 전송(벌크 연산 후 영속성 컨텍스트 초기화 필수)  

````java
int cnt = em.createQuery("update Member m set m.age = 26")
        .executeUpdate();  //변경이 발생한 엔티티 갯수 반환
em.clear();  //영속성 컨텍스트 초기화 필수
````

<br>

## Data Jpa
@Modifying 어노테이션 없을시 InvalidDataAccessApiUsageException 발생  
clearAutomatically 옵션을 통해 데이터베이스 변경사항 후 영속성 컨텍스트 초기화  

````java
@Modifying(clearAutomatically = true)
@Query("update Member m set m.age = m.age + 1 where m.age >= :age")
int bulkAgePlus(@Param("age") int age);
````

<br>
