## 연관관계 매핑시 고려사항
방향(direction) : 단방향과 양방향  
다중성(multiplicity) : 다대일(n:1), 일대다(1:n), 일대일(1:1), 다대다(n:m)  
연관관계 주인(owner) : 객체 양방향 연관관계에서 관리주인 필요  

<br>

## 객체를 테이블에 맞추어 모델링
외래키 식별자를 직접 사용해서 조인  
협력관계를 만들 수 없음  

````java
Team team = new Team();
team.setName("TeamA");
em.persist(team);  //영송상태가 되면 pk 값 보유

Member member = new Member();
member.setName("memberA");
member.setTeamId(team.getId());  //외래키 식별자를 직접 사용
em.persist(member);

Long findTeamId = findMember.getTeamId();
Team findTeam = em.find(Team.class, findTeamID);
````

<br>

## 단방향 연관관계 모델링
pk 값을 꺼내서 자동으로 fk 값과 매핑  
객체 지향적 참조를 통한 그래프 탐색 가능  

````java
public class Member {

    @ManyToOne(fetch = FetchType.EAGER)  //단방향 다대일 관계
    @JoinColumn(name = "TEAM_ID")  //실제 매핑되는 pk
    private Team team;
}

Team team = new Team();
team.setName("TeamA");
em.persist(team);  

Member member = new Member();
member.setName("memberA");
member.setTeam(team);  //단방향 연관관계 설정, 참조 저장
em.persist(member);

Team findTeam = member.getTeam();
````

<br>

## 양방향 연관관계
테이블 연관관계는 외래키 하나로 조인을 통한 양방향 가능(방향 개념이 없음)  

객체의 양방향 관계는 서로 다른 단방향 관계 2개  
    단방향 매핑만으로 이미 연관관계 매핑완료, 반대 방향 조회 기능이 추가된 것  
    단방향 매핑을 하고 필요시에 양방향 매핑 추가(JPQL 역방향 탐색이 필요한 경우)  

객체의 양방향 관계는 단방향 관계 2개 중 하나로 외래키 관리(연관관계 주인)  
````java
public class Team {
    
    @OneToMany(mappedBy = "team")  //연결된 fk 이름, 연관관계 주인 지정
    List<Member> members = new ArrayList<Member>();  //관례, 널포인트 오류 방지
}
````

<br>

## 연관관계 주인(Owner)

### 양방향 매핑 규칙
객체의 두 관계중 하나를 연관관계 주인으로 지정(비지느스 로직 기준과는 상관없음)  
외래키가 있는 곳을 주인으로 추천(Many 쪽: 주인)  
연관관계 주인만이 외래키 관리  
주인이 아닌 관계는 읽기만 가능  
주인은 mappedBy 속성 사용불가  
반대로 mappedBy 속성으로 연관관계 주인 설정  

### 보편적인 실수
연관관계의 주인에 값을 입력하지 않음(순수한 객체관계를 고려하면 항상 양쪽 모두 값을 입력)  
연관관계 편의 메소드 추천  
````java
public void changeTeam(Team team) {  //set은 관례, 좀더 로직 추가시 change
    this.team = team;
    team.getMembers().add(this);
}
````

양방향 매핑시 무한루프 주의

      toString(), lombok, JSON 생성 라이브러리

<br>

## 일대다 연관관계 주인
표준 스펙으로 지원하는 방식이지만 추천하지 않음  
DB 특성상 일대다여도 다쪽에 fk가 존재해야함  
객체와 테이블 차이로 인해 반대편 테이블의 외래키를 관리하는 구조  
일쪽 테이블의 변경사항에 다쪽 테이블까지 추가변경발생  
insert 쿼리문뿐만 아니라 다쪽 테이블 update 쿼리문이 추가로 발생  

### 일대다 단방향
````java
@OneToMany
@JoinColumn(name = "TEAM_ID")  //어노테이션 없는 경우 조인테이블 방식 사용(@JoinTable)
private List<Member> members = new ArrayKist<>(); 
````

### 일대다 양방향(표준 스펙은 아니지만 가능)
````java
@ManyToOne
@JoinColumn(name = "TEAM_ID", insertable = false, updatable = false)
private Team team;
````

<br>

## 일대일
주테이블이나 대상테이블 중 외래키 선택가능  
외래키에 데이터베이스 유니크(UNI) 제약조건 추가  
대상테이블에 외래키가 있는 단방향 관계는 지원하지 않음  

### 주테이블 외해키
주객체가 대상 객체의 참조를 가지는 것처럼 주테이블에 외래키를 두고 대상테이블 탐색  
상대적으로 객체지향적, JPA 매핑 편리  
값이 없으면 외래키에 null 값 허용  

### 대상 테이블 외래키
상대적으로 데이터베이스적   
주테이블과 대상테이블의 관계가 일대다로 변경할 경우 테이블 구조 유지  
프록시 기능의 한계로 지연로딩 불가(항상 즉시로딩)  

<br>

## 다대다
추천하지 않음  
객체는 컬렉션을 통해서 객체 2개로 다대다 관계가능  
관계형 데이터베이스는 정규화된 테이블 2개로 다대다 관꼐를 표현할 수 없음  
조인 테이블에는 연결에 필요한 정보만 존재, 부가적인 정보를 추가할 수 없음(실무 사용불가)  
다대다 관계를 사용하지 않고 연결 테이블을 추가해서 일대다, 다대일 관계로 표현  
    
### 단방향
````java
@ManyToMany
@JoinTable(name = "MEMBER_PRODUCT")  //조인테이블 이름설정
private List<Product> products = new ArrayList<>();
````

### 양방향
````java
@ManyToMany(mappedBy = "products")
private List<Member> members = new ArrayList<>();
````

<br>
