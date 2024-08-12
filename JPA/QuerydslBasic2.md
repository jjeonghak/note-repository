## 일반 조인
````java
List<Member> result = queryFactory
        .selectFrom(m)
        .join(m.team, t)  //on m.team_id = t.team_id
        .where(t.name.eq("teamA"))
        .fetch();
````

<br>

## 쎄타 조인
연관 관계가 없는 두 테이블을 조인  
카티션 곱으로 모든 행끼리 곱해서 표현(cross join 발생)  

````java
List<Member> result = queryFactory
        .select(m)
        .from(m, t)
        .where(m.username.eq(t.name))
        .fetch();
````

<br>

## 조인 on절
1. 외부조인 대상 필터링(leftJoin)  
내부조인인 경우 on절이 아닌 where절로 해결가능
````java
List<Tuple> result = queryFactory
        .select(m, t)
        .from(m)
        .leftJoin(m.team, t)
        .on(t.name.eq("teamA"))
        .fetch();
````

2. 연관관계 없는 엔티티 외부 조인
````java
List<Tuple> result = queryFactory
        .select(m, t)
        .from(m)
        .leftJoin(t)  //pk, fk 비교 on절 포함안됨
        .on(m.username.eq(t.name))
        .fetch();
````

<br>

## 페치 조인
````java
List<Member> result = queryFactory
        .selectFrom(m)
        .join(m.team, t)
        .fetchJoin()
        .where(m.username.eq("member1"))
        .fetch();
````

<br>

## 서브 쿼리
'com.querydsl.jpa.JPAExpression' 사용  
기존 쿼리의 Q 엔티티가 아닌 새로운 서브 쿼리의 Q 엔티티 필요  
JPA JPQL과 같이 from 절의 서브쿼리(인라인 뷰) 지원안함  

    1. 서브쿼리를 join으로 변경
    2. 애플리케이션에서 쿼리를 두번 분리
    3. nativeSQL 사용

````java
QMember mSub = new QMember("mSub");
List<Member> result = queryFactory
        .selectFrom(m)
        .where(m.age.in(
                JPAExpressions
                        .select(mSub.age)
                        .from(mSub)
                        .where(mSub.age.goe(10))
        ))
        .fetch();
````

<br>

## case문
조건이 복잡한 경우 CaseBuilder 사용  
````java
List<String> result = queryFactory
        .select(m.age
                .when(10).then("ten")
                .when(20).then("twenty")
                .otherwise("etc")
        )
        .from(m)
        .fetch();

List<String> result = queryFactory
        .select(new CaseBuilder()
                .when(m.age.between(0, 19)).then("under twenty")
                .when(m.age.between(20, 30)).then("between twenty and thirty")
                .otherwise("over thirty")
        )
        .from(m)
        .fetch();
````

<br>

## 상수 추가
JPQL 쿼리에는 상수 추구문 포함안됨  
결과에는 상수 추가  
````java
List<Tuple> result = queryFactory
        .select(m.username, Expressions.constant("A"))
        .from(m)
        .fetch();

// {username}_{age}
// age 데이터타입은 인트형이므로 concat(||) 불가, 형변환 필요(cast age as char)
List<String> result = queryFactory
        .select(m.username.concat("_").concat(m.age.stringValue()))
        .from(m)
        .fetch();
````

<br>
