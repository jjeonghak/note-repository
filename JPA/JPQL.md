## JPQL(Java Persistence Query Language)
SQL을 추상화한 객체지향 쿼리언어  
테이블 중심이 아닌 엔티티 객체 중심으로 개발  
테이블 쿼리가 아닌 객체 쿼리 작성  

<br>

## 단순조회
````java
EntityManager.find()
````

객체 그래프 탐색
````java
C typeC = member.getA().getB().getC()
````

<br>

## 조건조회
모든 회원 조회
````java
List<Member> result = em.createQuery("select m from Member as m",Member.class)
      .getResultList();
````
  
모든 회원 결과의 0번째 인덱스부터(limit) 10개(offset)의 인덱스 
````java
List<Member> result = em.createQuery("select m from Member as m",Member.class)
      .setFirstResult(0)
      .setMaxResults(10)
      .getResultList();
````

<br>

## Criteria
동적 쿼리문을 생성할때 효과적(JPQL 사용시 문자열끼리 복잡한 연산 필요, 쿼리문 오류 인지 불가)  
자바 메서드를 통한 쿼리 생성(쿼리문 오류시 컴파일 오류 발생으로 인지 가능)  
JPA 공식 기능이지만 너무 복잡하고 실용성이 없어 추천안함  

````java
//criteria builder 생성
CriteriaBuilder cb = em.getCriteriaBuilder();
CriteriaQuery<Member> query = cb.createQuery(Member.class);

//루트 클래스(조회를 시작할 클래스)
Root<Member> m = query.from(Member.class);

//쿼리 생성
CriteriaQuery<Member> cq = query.select(m).where(cb.equal(m.get("username"), "kim"));
em.createQuery(cq).getResultList();

//동적 쿼리 생성
if (username != null) {
    cq = cq.where(cb.equal(m.get("username"), "targetname"));
}
````

<br>

## QueryDSL
자바코드로 JPQL 작성(JPQL 빌더 역할)  
쿼리문 오류시 컴파일 오류 발생으로 인지 가능  
실무 사용 권장, 동적쿼리 작성 단순  

````java
JPAFactoryQuery query = new JPAQueryFactory(em);
QMember m = QMember.member;
List<Member> result = queryFactory
        .select(m)
        .from(m)
        .where(m.name.like("targetname")
        .orderBy(m.id.desc())
        .fetch();
````

<br>

## Native query
sql 표준 문법 그대로 사용하는 경우

````java
em.createNativeQuery("select * FROM MEMBER", Member.class).getResultList();
````

<br>

## JDBC(SpringJdbcTemplate 등)
기본적으로 jpa와 관련있는 쿼리는 자동 플러시 후 쿼리 전송  
JDBC 사용시 영속성 컨텍스트를 적절한 시점에 강제로 플러시 필요  
  
<br>
