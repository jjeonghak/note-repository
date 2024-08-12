## 동적쿼리
1. BooleanBuilder

2. where 다중 파라미터 사용

<br>

## BooleanBuilder
빌더를 통해 상황에 맞게 여러가지 조건 추가  
빌더 선언시 값 할당 가능(초기값 설정)  
````java
BooleanBuilder builder = new BooleanBuilder(m.username.eq(usernameParam));
````

특정상황에만 사용가능하며 재사용성이 낮음  
````java
private List<Member> searchMemberByBooleanBuilder(String usernameParam, Integer ageParam) {
    QMember m = QMember.member;
    BooleanBuilder builder = new BooleanBuilder();
    if (usernameParam != null) {
        builder.and(m.username.eq(usernameParam));
    }
    if (ageParam != null) {
        builder.and(m.age.eq(ageParam));
    }
    return queryFactory
            .selectFrom(m)
            .where(builder)
            .fetch();
}
````

<br>

## where 다중 파라미터 사용
where문에 null 조건은 무시  
조합이 가능하며 재사용성이 높은 비교메서드 생성  

````java
private List<Member> searchMemberByWhereParam(String usernameParam, Integer ageParam) {
    QMember m = QMember.member;
    return queryFactory
            .selectFrom(m)
            .where(usernameEq(usernameParam), ageEq(ageParam))
            .fetch();
}

private BooleanExpression usernameEq(String usernameParam) {
    QMember m = QMember.member;
    return usernameParam != null ? m.username.eq(usernameParam) : null;
}

private BooleanExpression ageEq(Integer ageParam) {
    QMember m = QMember.member;
    return ageParam != null ? m.age.eq(ageParam) : null;
}
````

조건들의 기본 타입은 Predicate, 메서드 조합을 위해 BooleanExpression 타입변경 추천
````java
private BooleanExpression allEq(String usernameParam, Integer ageParam) {
    return usernameEq(usernameParam).and(ageEq(ageParam));
}
````

<br>
