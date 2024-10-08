## JDBC 반복문제
커넥션 조회, 커넥션 동기화  
PreparedStatement 생성 및 파라미터 바인딩   
쿼리 실행  
결과 바인딩  
예외 발생시 스프링 예외 변환기 실행  
리소스 종료  

<br>

## JdbcTemplate
템플릿 콜백 패턴으로 JDBC 기술로 개발할 때 발생하는 반복을 해결  
트랜잭션을 위한 커넥션, 스프링 예외 변환 등 다양한 기능 제공  

````java
JdbcTemplate template = new JdbcTemplate(dataSource);
template.update(sql, sqlParam1, sqlParam2, ...);
template.queryForObject(sql, rowMapper(), sqlParam1, ...);

private RowMapper<Member> rowMapper() {
  return (rs, rowNum) -> {
    Member member = new Member();
    member.setMemberId(rs.getString("member_id"));
    return member;
  };
}
````

<br>

## 자동 식별키 사용
식별자 아이디로 데이터베이스가 생성한 자동키 사용하는 경우 KeyHolder 사용  

````java
KeyHolder keyHolder = new GeneratedKeyHolder();
template.update(connection -> {
  //자동 증가 키
  PreparedStatement ps = connection.prepareStatement(sql, new String[] {"id"});
  ps.setString(1, member.getMemberName());
  return ps;
}, keyHolder);
long key = keyHolder.getKey().longValue();
member.setMemberId(key);
````

<br>

## rowMapper
데이터베이스의 조회 결과를 객체로 변환할때 사용  
JdbcTemplate 자동 루프 생성, 개발자는 변환 코드만 작성  

````java
while (resultSet 끝날때까지) {
  rowMapper(rs, rowNum);
}
````

<br>
