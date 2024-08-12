## Q 클래스 인스턴스
별칭 직접 지정  
````java
QMember qMember = new QMember("m"); 
````

기본 인스턴스 사용
````java
QMember qMember = QMember.member;
````

<br>

## 검색 조건 쿼리
````java
m.username.eq("memberA")          // username = 'memberA'
m.username.ne("memberA")          // username != 'memberA'
m.username.eq("memberA").not()

m.username.isNotNull()            // username is not null

m.age.in(10, 20)                  // age in (10, 20)
m.age.notIn(10, 20)               // age not in (10, 20)
m.age.between(10, 20)             // age between 10 and 20

m.age.goe(10)                     // age >= 10
m.age.gt(10)                      // age > 10
m.age.loe(10)                     // age <= 10
m.age.lt(10)                      // age < 10

m.username.contains("member")     // like '%member%'
m.username.like("member%")        // like 'member%'
m.username.startsWith("member")   
````

<br>

## 결과 조회
````java
fetch()               // 리스트 조회(= getResultList)
fetchOne()            // 단건 조회(= getSingleResult)
fetchFirst()          // limit(1).fetchOne()
fetchResults()        // 페이징 정보 포함, total count 쿼리 추가 실행
fetchCount()          // count 쿼리로 변경해서 count 수 조회
````

<br>

## 정렬
````java
List<Member> result = queryFactory
      .selectFrom(m)
      .where(m.age.goe(30))
      .orderBy(m.age.desc(), m.username.asc().nullsLast())
      .fetch();
````

<br>

## 페이징
````java
List<Member> result = queryFactory
      .selectFrom(m)
      .orderBy(m.username.desc())
      .offset(1)
      .limit(2)
      .fetch();
````

<br>

## 집합
````java
List<Tuple> result = queryFactory
      .select(t.name, m.age.avg())
      .from(m)
      .join(m.team, t)
      .groupBy(t.name)
      .having(t.name.in("teamA", "teamB"))
      .fetch();
````

<br>
