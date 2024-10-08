## 기본 문법

select_문 :: = select_절 from_절 [where_절] [groupby_절] [having_절] [orderby_절]  
update_문 :: = update_절 [where_절]  
delete_문 :: = delete_절 [where_절]  

    select m from Member as m where m.age > 18
    
엔티티와 속성은 대소문자 구분(Member, age)  
JPQL 키워드는 대소문자 구분하지 않음(select, from, where)  
테이블 이름이 아닌 엔티티 이름사용  
별칭 m 필수(as 생략 가능)  

<br>

## 집합과 정렬

````
select
      count(m),    // 총 갯수
      sum(m.age),  // 속성값 합
      avg(m.age),  // 속성값 평균
      max(m.age),  // 속성값 최댓값
      min(m.age)   // 속성값 최솟값
from Member m
````

<br>

## 쿼리 종류
1. TypeQuery : 반환 타입이 명확할 때 사용
````java
TypeQuery<Member> query = em.createQuery("select m from Member m", Member.class);
````

2. Query : 반환 타입이 불명확할 때 사용
````java
Query<Member> query = em.createQuery("select m.name, m.age from Member m");
````

<br>

## 결과 조회 API
1. 리스트 반환 : 결과가 하나 이상인 경우
````java
// 결과가 없는 경우 빈 리스트
query.getResultList();
````
      
2. 단일 객체 반환 : 결과가 하나인 경우
````java
// 결과가 없는 경우 NoResultException
// 결과가 둘 이상인 경우 NonUniqueResultException
query.getSingleResult();
````

<br>

## 파라미터 바인딩
1. 이름 기준
````java
TypeQuery<Member> query = em.createQuery(
    "select m from Member m where m.id = :id", Member.class);
query.setParameter(name:"id", value:"10");
query.getResultList();
````

2. 위치 기준(추천안함, 위치는 쿼리 추가에 따라 달라질 수 있음)
````java
TypeQuery<Member> query = em.createQuery(
    "select m from Member m where m.id = ?1", Member.class);
query.setParameter(position:1, value:"10");
query.getResultList();
````

<br>
