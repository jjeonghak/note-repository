## JPA(Java Persistence API)
자바 진영의 ORM 기술 표준  
인터페이스의 모음(하이버네이트, EclipseLink, DataNucleus)  
EJB 엔티티빈(이전 자바 표준)의 문제점을 보완한 하이버네이트(오픈소스)에서 발전  
애플리케이션과 JDBC 사이에서 동작  
객체 지향 설계와 관계형 데이터베이스 설계의 패러다임 불일치 해결  

    상속, 연관관계, 객체 그래프 탐색, 비교

<br>

## ORM(Object-Relational Mapping)
객체 관계 매핑  
객체는 객체대로 관계형 데이터베이스는 관계형 데이터베이스대로 설계  
ORM 프레임워크를 통해 중간에서 매핑  
대중적인 언어는 대부분 ORM 기술 존재  

<br>

## JPA CRUD
sql 중심의 개발에서 객체지향적인 개발

    저장 : jpa.persist(member)
    조회 : Member member = jpa.find(memberId)
    수정 : member.setName("NewName")
    삭제 : jpa.remove(member)

<br>

## 성능 최적화  
1. 1차 캐시와 동일성 보장  
    같은 트랜잭션 안에서는 같은 엔티티 반환  
    같은 타입의 데이터가 두번째 호출될때부터 캐시데이터 반환  

    ````java
    String memberId = "1";
    Member m1 = jpa.find(Member.class, memberId);  //sql 쿼리 전송
    Member m2 = jpa.find(Member.class, memberId);  //캐시
    Assertion.assertThat(m1).isSameAs(m2);
    ````

<br>
  
2. 트랜잭션을 지원하는 쓰기 지연(transaction write-behind)  
      트랜잭션 커밋할 때까지 INSERT SQL을 모음  
      JDBC BATCH SQL 기능을 사용해서 한번에 전송
   
      ````java
      transaction.begin();  //트랜잭션 시작
      em.persist(m1);
      em.persist(m2);
      em.persist(m3);  //sql 쿼리 전송 지연
      transaction.commit();  //트랜잭션 커밋과 함께 지연되었던 sql 쿼리 전송
      ````

<br>

3. 지연 로딩(lazy loading)과 즉시 로딩  
      지연 로딩과 즉시 로딩 지원  
      상황에 맞게 혼합해서 사용가능
   
      지연 로딩 : 객체가 실제 사용될 때 로딩
      ````java
      Member member = memberDAO.find(memberId);  //SELECT * FROM MEMBER
      SubMember subMember = member.getSubMember();
      String subName = subMember.getName();  //SELET * FROM SUBMEMBER
      ````
          
      즉시 로딩 : 객체를 생성하는 순간 관련된 모든 데이터 로딩
      ````java
      Member member = memberDAO.find(memberId);  //SELECT M.*, S.* FROM MEMBER JOIN SUBMEMBER ON ...
      ````

<br>
