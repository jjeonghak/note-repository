## 조인 종류
1. 내부조인
````java
//m.team 없는 경우 조인안됨
select m from Member m [inner] join m.team t
````

2. 외부조인
````java
//m.team 없는 경우 null로 조인
select m from Member m left [outer] join m.team t
````

3. 세타조인
````java
//연관관계가 없는 두 테이블을 비교절에 맞게 조인(cross join)
select count(m) from Member m, Team t where m.name = t.name
````

<br>

## JPQL 조인 방식
1. 명시적 조인 : 일반적인 sql 쿼리처럼 join 키워드 직접 사용해서 명시적으로 조인 여부 표현한 쿼리
````
select t.members from Team t join t.members m
````

2. 묵시적 조인 : 조인 여부를 직접 표현하지 않지만 다른 엔티티 객체를 내부조인해야하는 쿼리
````
selet t.members from Team t
````

<br>

## on절
1. 조인 대상 필터링

       JPQL
            select m, t from Member m left join m.team t on t.name = ?
   
       SQL(pk와 fk 비교절 포함)
            SELECT m.*, t.* FROM Member m LEFT JOIN Team t ON m.TEAM_ID = t.id and t.name = ?
        
2. 연관관계 없는 엔티티 외부 조인

       JPQL
            select m, t from Member m left join team t on m.name = t.name

       SQL
            SELECT m.*, t.* FROM Member m LEFT JOIN Team t ON m.name = t.name

<br>
