## 페이징
fetchResult() 대신 count 쿼리와 fetch() 사용  

````java  
public Page<MemberTeamDto> searchPage(MemberSearchCondition condition, Pageable pageable) {
      Long count = queryFactory
              .select(m.count())
              .from(m)
              .leftJoin(m.team, t)
              .where(
                      usernameEq(condition.getUsername()),
                      teamNameEq(condition.getTeamName()),
                      ageGoe(condition.getAgeGoe()),
                      ageLoe(condition.getAgeLoe())
              )
              .fetchOne();

      List<MemberTeamDto> content = queryFactory
              .select(new QMemberTeamDto(
                      m.id.as("memberId"), m.username, m.age,
                      t.id.as("teamId"), t.name.as("teamName")
              ))
              .from(m)
              .leftJoin(m.team, t)
              .where(
                      usernameEq(condition.getUsername()),
                      teamNameEq(condition.getTeamName()),
                      ageGoe(condition.getAgeGoe()),
                      ageLoe(condition.getAgeLoe())
              )
              .offset(pageable.getOffset())
              .limit(pageable.getPageSize())
              .fetch();

      return new PageImpl<>(content, pageable, count);
  }
````

<br>

## count 쿼리 최적화
생략가능한 경우
 
    1. 페이지 시작이면서 컨텐츠 사이즈가 페이지 사이즈보다 작은 경우
    2. 마지막 페이지인 경우(offset + 컨텐츠 사이즈)

````java
// count 쿼리문이 생략가능한 경우는 totalSupplier 실행안함
JPAQuery<Long> countQuery = queryFactory
          .select(m.count())
          .from(m)
          .leftJoin(m.team, t)
          .where(
                  usernameEq(condition.getUsername()),
                  teamNameEq(condition.getTeamName()),
                  ageGoe(condition.getAgeGoe()),
                  ageLoe(condition.getAgeLoe())
          );

return PageableExecutionUtils
          .getPage(content, pageable, () -> countQuery.fetchOne());
````

<br>
