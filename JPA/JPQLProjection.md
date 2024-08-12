## 프로젝션
select 절에 조회할 대상을 지정하는 것  
반환된 프로젝션들은 영속성 컨텍스트에 의해 관리  
대상 : 엔티티, 임베디드 타입, 스칼라 타입  

````java
select m from Member m                        // 엔티티 프로젝션
select m.team from Member m                   // 엔티티 프로젝션
select m.address from Member m                // 임베디드 타입 프로젝션
select distinct m.name, m.age from Member m   // 스칼라 타입 프로젝션
````

<br>

## 프로젝션 여러값 조회

````
select distinct m.name, m.age from Member m
````

1. Query 타입 조회
  ````java
  List result = em.createQuery("select distinct m.name, m.age from Member m")
          .getResultList();
  Object o = result.get(0);
  Object[] r = (Object[]) o;  // r[0] : name, r[1] : age
  ````

2. Object[] 타입 조회
  ````java
  List<Object[]> result = em.createQuery("select distinct m.name, m.age from Member m")
          .getResultList();
  ````
  
3. new 명령어 조회
  단순값을 DTO로 바로 조회(쿼리문에서 DTO 생성자에 값 대입하는 것처럼 사용)  
  패키지 명을 포함한 전체 클래스 명 입력  
  순서와 타입이 일치하는 생성자 필요  
  
  ````java
  public class MemberDTO {
      private String name;
      private int age;
      
      public MemberDTO(String name, int age) {
          this.name = name;
          this.age = age;
      }
  }
  
  List<MemberDTO> result = em.createQuery(
          "select new jpql.MemberDTO(m.name, m.age) from Member m", MemberDTO.class)
          .getResultList();
  ````

<br>

## 엔티티 프로젝트 직접 사용
JPQL에서 엔티티를 직접 사용하면 sql에서 해당 엔티티의 pk 값을 사용  

````
JPQL
    select count(m.id) from Member m  // 엔티티의 데이터 사용
    select count(m) from Member m     // 엔티티 직접 사용

SQL
    SELECT COUNT(M.ID) FROM MEMBER M 
````

<br>

## 엔티티 속성 조회
엔티티 전체가 아닌 일부 속성(프로젝트)만 조회하는 경우  
인터페이스인 경우 프록시 객체, 구현체인 경우 실제 객체사용  

<br>
  
### 인터페이스 사용
````java
// close projections : 원하는 프로젝션만 가져와서 반환
public interface UsernameOnly {
    String getUsername();
}

// open projections : 엔티티 전체를 가져와서 연산후 반환
public interface UsernameOnly {
    @Value("#{target.id + ' ' + target.username}")
    String getUsername();
}
````

<br>

### 구현체 사용
````java
public class UsernameOnlyDto {
    private final String username;
    public UsernameOnlyDto(String usernmae) {
        this.username = username;
    }
    public String getUsername() {
        return username;
    }
}
````

<br>

### 동적 프로젝션
````java
<T> List<T> findProjectionsByUsername(@Param("username") String username, Class<T> type);

List<UsernameOnlyDto> result = memberRepository
        .findProjectionsByUsername('member1', UsernameOnlyDto.class)
````

<br>

### 중첩 프로젝션
기본적으로 두번째 엔티티 필드부터는 엔티티 전체를 조회

````java
public interface NestedClosedProjections {
    String getUsername();
    TeamInfo getTeam();
    
    interface TeamInfo {
        String getName();
    }
}
````

<br>

### 네이티브 쿼리
````java
@Query(value = "select m.member_id as id, m.username, t.name as teamName from member m left join team t",
        countQuery = "select count(*) from member", nativeQuery = true
)
Page<MemberProjections> findByNativeProjection(Pageable pageable);
````

<br>
