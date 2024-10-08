## 프로젝션 대상
단일 대상인 경우 타입을 명확하게 지정가능  
둘 이상인 경우 튜플이나 DTO 사용  

<br>

## 튜플 조회
'com.querydsl.core' tuple 사용  
레포지토리 계층까지만 사용(하위 패키지를 상위 계층에서 의존하는 경우 발생)  

````java
List<Tuple> result = queryFactory
      .select(m.username, m.age)
      .from(m)
      .fetch();
result.get(index: 0).get(expression: m.username);
result.get(index: 0).get(expression: m.age);
````

<br>

## DTO 조회
순수 JPA 방식은 new 명령어를 사용한 생성자 방식만 지원  
querydsl 빈 생성(bean population)  

1. 프로퍼티 접근 : setter 필요
````java
List<MemberDto> result = queryFactory
      .select(Projections.bean(MemberDto.class, m.username, m.age))
      .from(m)
      .fetch();
````

2. 필드 직접 접근 : getter, setter 없이 바로 필드 접근(private 접근제어에도 문제없음)
````java
List<MemberDto> result = queryFactory
      .select(Projections.fields(MemberDto.class, m.username, m.age))
      .from(m)
      .fetch();
````

3. 생성자 사용 : constructor 필요, 이름 매칭이 아닌 타입 매칭
````java
List<MemberDto> result = queryFactory
      .select(Projections.constructor(MemberDto.class, m.username, m.age))
      .from(m)
      .fetch();
````

### 프로퍼티 및 필드 접근 생성 방식에서 필드명과 파라미터명 매칭이 안될경우 null 삽입
1. ExpressionUtils.as(source, alias) : 필드나 서브쿼리에 별칭 적용  

2. username.as("name") : 필드에 별칭 적용(= ExpressionUtils.as(m.username, "name"))  

````java
List<UserDto> result = queryFactory
      .select(Projections.fields(UserDto.class,
              m.username.as("name"),
              ExpressionUtils.as(JPAExpressions
                    .select(mSub.age.max())
                    .from(mSub), "age")
      ))
      .from(m)
      .fetch();
````

<br>

## 프로젝션 결과 반환
dto 생성자에 @QueryProjection 어노테이션 적용후 compileQuerydsl  
생성자 사용방식은 런타임 중에 오류발견, 이방식은 컴파일 시점에 오류발견  
dto class가 querydsl에 대한 의존성 생성(import com.querydsl)  

````java
@QueryProjection
public MemberDto(String username, int age) {
    this.username = username;
    this.age = age;
}

List<MemberDto> result = queryFactory
      .select(new QMemberDto(m.username, m.age))
      .from(m)
      .fetch();
````

<br>
