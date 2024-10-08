## 메소드에 쿼리 정의
쿼리 메서드의 단점인 많은 양의 파라미터인 경우 보완  
직접 레포지토리에 정의하여 사용하므로 이름없는 네임드 쿼리  
네임드 쿼리와 같이 쿼리문법 오류에 대해 애플리케이션 로딩시점에 컴파일 오류발생   

````java
@Query("select m from Member m where m.username = :username and m.age = :age")
List<Member> findByUsernameAndAge(@Param("username") String username, @Param("age") int age);
````

<br>

## DTO 조회
````java
@Query("select new spring.datajpa.dto.MemberDto(m.id, m.username, t.teamName) from Member m join m.team t")
List<MemberDto> findMemberDto();
````

<br>

## 컬렉션 파라미터 바인딩
````java
@Query("select m from Member m where m.username in :names")
List<Member> findByNames(@Param("names") List<String> names);
````

<br>

## 반환타입
단건조회의 경우 조건에 맞는 데이터가 없으면 NoResultException 캐치후 null 반환  
단건조회의 경우 조건에 맞는 데이터가 두개 이상인 경우 NonUniqueResultException(data jpa) 발생  

      IncorrectResultSizeDataAccessException(spring)으로 변환

리스트는 조건에 맞는 데이터가 없으면 빈 리스트 반환
````java
Member findMemberByUsername(String username);
List<Member> findListByUsername(String username);
Optional<Member> findOptionalByUsername(String username);
````

<br>

