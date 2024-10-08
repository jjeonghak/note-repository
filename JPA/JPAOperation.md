## 구동 방식
1. Persistence 클래스가 META-INF/persistence.xml 설정 정보 조회, 기본적으로 Persistence.class 존재

2. 설정 정보를 통해 EntityManagerFactory 생성

````java
//persistenceUnitName은 persistence.xml 설정 정보에 포함
EntityManagerFactory emf = Persistence.createEntityManagerFactory("persistenceUnitName");
````

3. EntityManagerFactory는 필요에 따라 EntityManager 생성

````java
EntityManager em = emf.createEntityManager();
````

4. 모두 사용후 연결 종료

````java
em.close();
emf.close();
````

<br>

## 테이블 매핑
JDBC URL과 persistence.xml의 설정 정보를 동일하게 처리해야함  
DB 하나당 하나의 엔티티매니저팩토리 생성, 보통 애플리케이션 전체에서 하나 공유  
엔티티매니저는 쓰레드 간의 공유 금지(일회용)  
데이터베이스의 데이터를 변경하는 작업은 무조건 트랜잭션 단위로 작업해야함  

````java
EntityTransaction tx = em.getTransaction();  //EntityManager에게 트랜잭션 받기
tx.begin();  //트랜잭션 시작, 이후 데이터베이스 데이터 변경
tx.commit();  //트랜잭션 커밋
tx.rollback();  //문제 발생시 트랜잭션 롤백, 실제 변경점이 데이터베이스에 적용되지 않음
````

사용하는 엔티티 클래스에 @Entity 어노테이션 추가  
테이블을 지정해서 매핑하려면 @Table(name = "TableName") 어노테이션 추가  
primary key 멤버 인스턴스는 @Id 어노테이션 추가  
````java
@Id private Long id
````

테이블 내의 속성 지정 매핑하려면 @Column(name = "attributeName") 어노테이션
````java
@Column(name = "name") private String name
````

<br>

## 회원 등록
````java
try {
      Member member = new Member();
      member.setId(idNum);
      member.setName(nameString);

      em.persist(member);
      tx.commit();
} catch(Exception e) {
      tx.rollback();
} finally {
      em.close();
}
````

<br>

## 회원 삭제
````java
Member findMember = em.find(Member.class, primaryKey);
em.remove(findMember);
````

<br>

## 회원 수정
객체지향과 같이 값만 바꾸어도 커밋할때 jpa에서 update 쿼리를 전송  
jpa를 통해 엔티티를 가져오면 그 엔티티는 jpa가 관리  

````java
Member findMember = em.find(Member.class, primaryKey);
findMember.setName("newName");
````

<br>
