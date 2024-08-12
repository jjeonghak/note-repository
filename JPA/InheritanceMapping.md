## 상속관계 매핑
관계형 데이터베이스는 상속관계 없음  
슈퍼타입 서브타입관계 모델링 기법이 객체상속과 유사  

````java
public abstract class ParentClass
public class ChildClass extends ParentClass
````

<br>

## 논리 모델을 실제 물리 모델로 변환하는 방법
1. 조인 전략(JOINED) : 각각 테이블로 변환, 가장 객체지향적 상속과 유사한 구조  
    테이블 정규화를 통해 저장공간 효율화  
    외래키 참조 무결성 제약조건 활용가능  
    부모 테이블과 자식 테이블이 각각 존재, fk 필요  
    자식 테이블은 부모 테이블의 pk를 fk로 사용하면서 동시에 pk로 사용

    ````java
    @Inheritance(strategy = InheritanceType.JOINED)
    @DiscriminatorColumn(name = "DTYPE")  //DTYPE 속성 추가, 자식 클래스명을 도메인으로 사용
    @DiscriminatorValue("entityName")  //자식 클래스명이 아닌 이름을 도메인으로 사용
    ````

<br>

2. 단일 테이블 전략(SINGLE_TABLE) : 통합 테이블로 변환, default  
    부모 테이블과 자식 테이블의 모든 속성을 하나의 테이블로 관리  
    조회 쿼리가 단순  
    자식 엔티티가 매핑한 속성은 모두 null 허용(자식 클래스 종류에 따라 값이 들어가는 속성 다름)
    ````java
    @Inheritance(strategy = InheritanceType.SINGLE_TABLE)
    @DiscriminatorColumn  //생략해도 DTYPE 속성 생성, 알수 있는 방법이 없음
    ````

<br>

3. 구현 클래스마다 테이블 전략(TABLE_PER_CLASS) : 서브타입 테이블로 변환  
    추천하지 않음  
    부모 테이블을 제거하고 그 속성을 자식 테이블에 각각 추가  
    데이터를 생성하는 것이 수월하지만 조회 및 수정이 번거로움(모든 자식 테이블 탐색)  
    not null 제약조건 사용가능  
    각각의 테이블이 존재하므로 @DiscriminatorColumn 의미 없음

    ````java
    @Inheritance(strategy = InheritanceType.TABLE_PER_CLASS)
    ````
      
<br>

## @MappedSuperclass
공통 매핑 정보가 필요할 때 사용(id, name, createdBy, modifiedBy)  
직접 인스턴스를 생성하지 않으므로 추상클래스 추천  
엔티티가 아니기 때문에 따로 테이블 생성 안함, 상속관계 매핑 아님  
상속받은 자녀 클래스 테이블에 속성 생성(구현 클래스마다 테이블 전략과 유사)  
구현 클래스마다 테이블 전략과 다르게 부모 클래스로 조회불가(매핑되지 않음)  

<br>
