## JPA 데이터 타입 분류
1. 엔티티 타입  
@Entity 정의 객체  
데이터가 변해도 식별자로 지속적인 추적가능  
        
2. 값 타입  
자바 기본 타입(int, String)이나 객체  
식별자가 없고 값만 있으므로 변경시 추적불가  

<br>

## 값 타입
1. 기본값 타입  
2. 임베디드 타입(embedded type, 복합 값 타입)  
3. 컬렉션 값 타입(collection value type)  

<br>

## 기본값 타입
생명주기를 엔티티에 의존
값 타입은 공유금지(부수효과 금지)

1. 자바 기본 타입(primitive type)  
항상 값을 복사해서 사용하므로 공유되지 않음  
````java
int a = 10;
int b = a;
a = 20;      // a == 20, b == 10, pass by Value
````

2. 래퍼 클래스(wrapper class),특수한 클래스(String)  
공유가능하지만 변경은 불가(참조를 위한 인스턴스)  
산술 연산을 위해 정의된 클래스가 아니므로 인스턴스에 저장된 값 변경불가  
박싱으로 동등 연산자 비교는 언제나 false  
오토박싱으로 비교시 -128 ~ 127까지는 캐싱데이터 사용으로 true  
````java
Integer num = new Integer(10);      // 박싱(boxing)
int n = num.intValue();             // 언박싱(unboxing)
Character ch = 'X';                 // 오토박싱(autoboxing)
char c = ch;                        // 오토언박싱(autounboxing)
````    

<br>

## 임베디드 타입
새로운 값 타입을 직접 정의 가능  
JPA는 임베디드 타입  
주로 기본 값 타입을 모아서 만들기 때문에 복합 값 타입  
기본 값 타입의 모임이므로 임베디드 타입도 값 타입과 유사  
부모 엔티티의 생명주기에 의존(연관관계 OneToOne과의 차이)  
데이터베이스 테이블은 임베드디 타입 사용 유무에 따라 변경사항 없음  
재사용과 높은 응집도, 엔티티의 값일 뿐  

````
@Embeddable : 값 타입 정의하는 곳에 어노테이션 추가, 기본생성자 필수
@Embedded : 값 타입 사용되는 곳에 어노테이션 추가
@AttributeOverrides : 한 엔티티에서 재사용시 컬럼명 속성 재정의
@AttributeOverride : 한 엔티티에서 재사용시 컬럼명 속성 재정의
````

````java
@AttributeOverrides({@AttributeOverride(name = "columnName", column = @Column(name = "NEW_COLUMN_NAME")})
````

<br>

## 객체 타입의 한계
항상 값을 복사해서 사용하면 공유 참조로 인해 발생하는 부수효과 예방가능  
임베디드 타입처럼 직접 정의한 값 타입은 자바의 기본 타입이 아니라 객체 타입(객체의 공유참조 발생)  

<br>

## 불변 객체(immutable object)
생성 시점 이후 값 변경이 불가능한 객체  
객체 타입을 수정할 수 없게 만들어서 부수효과 방지  
값 타입은 불변객체로 설계(생성자로만 값 설정, 수정자 생성 금지)  
자바가 제공하는 대표적인 불변 객체 : Integer, String  

<br>

## 값 타입 비교
동일성(identity) : 인스턴스 참조값 비교(==)  
동등성(equivalence) : 인스턴스 값을 비교(equals())  
객체의 동등성 비교는 Object 클래스의 equals()와 hashCode() 오버라이드하여 재정의  

    equals()는 기본적으로 == 비교로 구현되어 있지만 값 타입 클래스에서 오버라이드하여 사용
    equals() 구현시 get 메서드 필수(프록시 객체인 경우 고려)
    hashCode()는 public native 키워드를 이용하는 JNI(Java Native Interface)
    hashCode는 HashTable, HashSet, HashMap 같은 자료구조의 저장위치 선택에 사용

동일한 객체는 동일한 메모리 주소와 해시코드를 가지고 있어야함

    obj1.equals(obj2) == true이면 hashCode(obj1) == hashCode(obj2)
 
<br>

## 값 타입 컬렉션
일반적인 일대다 관계가 아닌 객체 내에서 값 타입을 하나 이상 저장할 때 사용   
데이터 베이스는 컬렉션을 테이블에 표시하는 기능 지원안하므로 따로 테이블 생성  
영속성 전이, 지연로딩, 고아 객체 제거와 유사한 기능 보유  
````java
@OrderColumn  // 컬렉션 테이블에 pk 생성, 연속되지 않은 pk값인 경우 null 생성
@ElementCollection(fetch = FetchType.LAZY)
@CollectionTable(name = "COLLECTION_TABLE_NAME", joinColumns = @JoinColumn(name = "MEMBER_ID"))
````

<br>

### 수정
기존값 삭제 후 추가
````java
// List
findMember.getList().remove(removeTarget);
findMember.getList().add(addTarget);
    
// Set<> - hashCode와 equals를 이용해서 기존 데이터와 똑같은 데이터를 생성해서 삭제
findMember.getHashSet().remove(new Target(target.p1, target.p2));
findMember.getHashSet().add(new Target(newTarget.p1, newTarget.p2));
````

<br>

### 제약사항
값 타입이므로 식별자 개념이 없고 변경시 추적 불가  
값 타입 컬렉션 변경시 주인 엔티티와 연관된 컬렉션 데이터 삭제후 컬렉션 내의 모든 값을 다시 저장  
값 타입 컬렉션을 매핑하는 테이블은 모든 컬럼을 묶어서 pk 구성(null, 중복 방지)  

<br>

## JPQL 타입 표현
문자 : 'string', 'she''s'  //문자형 (') 표현은 ('')  

숫자 : 10L, 10D, 10F  

boolean : true false  

enum : jpql.MemberEnumType.ADMIN  

    // 패키지명 포함필수, 또는 파라미터 바인딩
    select m from Member m where m.type = :enumType
    .setParameter("enumType", MemberEnumType.ADMIN)

엔티티 : type(m) = Member  
    
    // 상속관계에서 사용  
    select i from Item i where type(i) = Book




