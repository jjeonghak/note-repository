## 엔티티 매핑
### 객체와 테이블(@Entity, @Table)

@Entity 
    
    어노테이션이 붙은 클래스는 JPA가 관리
    파라미터가 없는 기본 생성자 필수
    final, enum, interface, inner 클래스 사용불가

@Table
    
    name : 매핑할 테이블 이름, default = entityName
    catalog : 데이터베이스 카탈로그 매핑
    schema : 데이터베이스 스키마 매핑
    uniqueConstraints(DDL) : DDL 생성 시 유니크 제약 조건 생성

<br>

### 필드와 컬럼(@Column)

@Column

    칼럼 매핑
    name : 필드와 매핑할 테이블의 칼럼 이름
    insertable, updatable : 등록, 변경 가능 여부, default = true
    nullable(DDL) : null 값 허용여부 설정
    unique(DDL) : @Table(uniqueConstraints)과 유사, 한 컬럼에 간단히 유니크 제약조건
    columnDefinition(DDL) : 데이터베이스 컬럼 정보를 직접 전달, varchar(100) default 'EMPTY'
    length(DDL) : 문자길이 제약조건, String 타입에만
    precisionm, scale(DDL) : BigDecimal, BigInteger 타입에 사용, 소숫점 포함 전체 자릿수
  
@Enumerated(EnumType.STRING)

    enum 타입 매핑(ORDINAL, STRING)
    ORDINAL : 운영DB에 사용금지, enum의 순서를 데이터베이스에 저장, defualt
    STRING : enum의 이름을 데이터베이스에 저장
  
  
@Temporal(TemporalType.TIMESTAMP)

    날짜 타입 매핑(DATE, TIME, TIMESTAMP)
    Java8에서는 LocalDate, LocalDateTime 사용
    DATE : 날짜, 데이터베이스 date 타입과 매핑(2022-05-14)
    TIME : 시간, 데이터베이스 time 타입과 매핑(17:02:11)
    TIMESTAMP : 날짜와 시간, 데이터베이스 timestamp 타입과 매핑(2022-05-14 17:02:11)

@Lob

    BLOB, CLOB 매핑
    지정할 수 있는 속성없음
    매핑하는 필드의 타입이 문자면 CLOB, 나머지는 BLOB 매핑
  
@Transient

    특정 필드를 칼럼과 매핑을 원치않는 경우, 메모리에서만 사용

<br>

### 기본 키(@Id)

  @Id : 직접 할당
  @GeneratedValue(strategy = GenerationType.AUTO) : 자동 생성
  
    [IDENTITY]
    MYSQL 데이터베이스에 위임, 직접 값 할당 불가(null 필수)
    데이터베이스에 플러시 되기전까지 식별자 id 값을 알수 없음
    예외적으로 em.persist()와 함께 바로 insert sql 쿼리문 전송
        
    [SEQUENCE]
    ORACLE 데이터베이스 시퀀스 오브젝트 사용(@SequenceGenerator)
    식별자 id 값을 모르므로 em.persist()와 함께 데이터베이스를 통해 시퀀스 pk값 받음
    하지만 insert sql 쿼리문 전송되지는 않음
    멤버 생성시마다 네트워크를 통해 시퀀스 pk 값을 가져오는 문제발생
    allocationSize를 이용해서 한번 네티워크를 통해 허용된 갯수만큼 미리 등록 후 메모리로 사용
            
          @SequenceGenerator(name = "MEMBER_SEQ_GENERATOR",
              sequenceName = "MEMBER_SEQ",  //매핑할 테이블이름
              initialValue = 1, allocationSize = 50  //초기값, 허용갯수)
          @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "MEMBER_SEQ_GENERATOR")
                
    [TABLE]
    키 생성용 테이블 사용(@TableGenerator)
        
          @TableGenerator(name = "MEMBER_SEQ_GENERATOR", table = "MY_SEQUENCES", pkColumnValue = "MEMBER_SEQ", allocationSize = 1)
          @GeneratedValue(strategy = GenerationType.TABLE, generator = "MEMBER_SEQ_GENERATOR")
            
    [AUTO]
    방언에 따라 자동 지정, default
      
  ### 연관관계(@ManyToOne, @JoinColumn)

<br>
      
## 데이터베이스 스키마 자동 생성

[persistence.xml]
````xml
<property name="hibernate.hbm2ddl.auto" value="create"/>
````

create : 운영DB에 사용금지, 기존 테이블 삭제 후 다시 생성, DROP + CREATE  
create-drop : 운영DB에 사용금지, create + DROP  
update : 운영DB에 사용금지, 변경부분(추가)만 반영, ALTER  
validate : 엔티티와 테이블이 정상 매핑되었는지만 확인  
none : 사용하지 않음  

<br>
