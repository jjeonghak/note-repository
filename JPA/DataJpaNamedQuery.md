## 네임드 쿼리
미리 정의해서 이름을 부여해두고 사용하는 JPQL  
네임드 쿼리가 쿼리메서드보다 우선순위가 높음(변경가능)  
정적쿼리(어노테이션, xml에 정의)  
애플리케이션 로딩 시점에 쿼리를 검증  

### Member 엔티티에 선언
````java
@NamedQuery(
        name = "Member.findByUsername",
        query = "select m from Mwmber m where m.username = :username"
)

//JpaRepository 선언, @Query 어노테이션 생략가능(데이터 타입의 엔티티에 네임드쿼리 탐색)
//@Param 어노테이션은 확실한 jpql에 :username 선언되어 있기때문에 사용
@Query(name = "Member.findByUsername")
List<Member> findByUsername(@Param("username") String username);

em.createNameQuery("Member.findByUsername", Member.class)
    .setParameter("username", "member1")
    .getResultList()
````

<br>

## xml 정의
xml 우선순위 높음  
애플리케이션 운영환경에 따라 다른 xml 배포가능  
    
[META-INF/persistence.xml]
````xml
<persistence-unit name="jpql">
    <mapping-file>META_INF/ormMember.xml</mapping-file>

[META-INF/ormMember.xml]
<?xml version="1.0" encoding="UTF-8"?>
<entity-mappings xmlns="http://xmlns.jcp.org/xml/ns/persistence/orm" version="2.1">
    <named-query name="Member.findByName">
        <query><![CDATA[
            select m
            from Member m
            where m.name = :name
        ]]></query>
    </named-query>
</entity-mappings>
````

<br>
