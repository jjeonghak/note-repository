## 서브 쿼리 지원 함수
[NOT] EXISTS (subquery) : 서브쿼리 결과 존재시 참
````
// A팀 소속 회원
select m from Member m
where EXISTS (select t from m.team t where t.name = "A")  
````

<br>

[NOT] IN (subquery) : 서브쿼리 결과 중 하나라도 같은 것 존재시 참
````
// 나이가 가장 많거나 적은 회원
select m from Member m
where m.age IN (select min(m1.age), max(m1.age) from Member m1)
````

<br>

{ALL | ANY | SOME} (subquery)
````
ALL : 모두 조건을 만족하면 참
ANY, SOME : 조건을 하나라도 만족하면 참

// 전체 상품 각각의 재고보다 주문량이 많은 주문들
select o from Order o
where o.orderAmount > ALL (select p.stockAmount from Product p)  

// 어떤 팀에든 소속된 회원
select m from Member m
where m.team = ANY (select t from Team t)
````

<br>

## JPA 서브쿼리 한계
where, having 절에서만 서브쿼리 사용가능  
select 절도 가능(하이버네이트에서 지원)  
from 절의 서브쿼리는 불가능  

<br>
