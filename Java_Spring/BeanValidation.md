## Bean Validation
특정 필드에 대한 검증 로직은 대부분 빈 값, 범위 내의 값 검증로직이 일반적인 로직  
검증 로직을 모든 프로젝트에 적용할 수 있게 공통화 및 표준화  
스프링 부트는 라이브러리 추가시 자동으로 bean validator 인지하고 스프링에 통합  
특정한 구현체가 아닌 Bean Validation 2.0(JSR-380) 기술 표준(여러 어노테이션과 인터페이스 모음)  
  
````java
implementation 'org.springframework.boot:spring-boot-starter-validation'
````

<br>

## 검증 어노테이션
javax.validation.constraints.xxx : 특정 구현에 관계없이 제공되는 표준 인터페이스  
org.hibernate.validator.constraints.xxx : 하이버네이트 validator 구현체를 사용할 때만 제공  
  
    @NotBlank : 빈값 + 공백만 있는 경우를 허용하지 않음
    @NotNull : null 값을 허용하지 않음
    @Range(min, max) : 범위 안의 값만 허용
    @Max, @Min : 최대, 최소

<br>

## 검증기 생성 및 실행
스프링과 통합하기 전 검증기 필수 생성  
검증 대상을 직접 검증기에 넣고 그 결과를 반환, 결과가 비어있지 않다면 검증 오류 존재  

````java
ValidatorFactory factory = validation.buildDefaultValidatorFactory();
Validator validator = factory.getValidator();
Set<ConstraintViolation<TargetClass>> violations = validator.validate(target);
````

<br>

## LocalValidatorFactoryBean
글로벌 validator로 등록  
객체의 @NotNull 어노테이션등을 보고 검증 실행  
@Valid, @Validated 어노테이션 적용된 모델객체만 적용  
만약 직접 글로벌 validator 등록하면 스프링 부트는 bean validator 등록하지 않음  

<br>

## 검증 순서
1. @ModelAttribute 모델객체 각각의 필드에 타입 변환시도  
    1) 성공시 다음으로  
    2) 실패시 typeMismatch FieldError 추가  
  
2. Validator 적용  
    바인딩에 성공한 필드만 Bean Validator 적용  
  
<br>

## ErrorCodes
어노테이션 이름 그대로 오류코드 등록  
어노테이션 이름을 기반으로 MessageCodesResolver를 통해 다양한 메시지 코드가 순서대로 생성  

    @NotBlank
      NotBlank.item.itemName
      NotBlank.itemName
      NotBlank.java.lang.String
      NotBlank

<br>

## ObjectError
해당 객체에 글로벌 오류 검증을 위해 객체에 @ScriptAssert 어노테이션 추가(권장하지 않음)  
````java
@ScriptAssert(lang = "javascript", script = "_this.price * _this.quantity >= 10000", message = "총합 10000 이상")
public class Item {}
````
사용제약이 많고 복잡한 글로벌 오류인 경우 직접 자바코드로 구현  

<br>

## groups
동일한 모델객체를 상황에 따라 다른 요구사항으로 검증할 때 사용(권장하지 않음)  
상황에 따른 인터페이스 생성  
각 검증인터페이스에 상황 인터페이스 적용  
````java
@NotNull(groups = {SaveCheck.class, UpdateCheck.class})
@Validated(UpdateCheck.class)
````
@Valid 어노테이션에는 적용불가  

<br>

## form 전송 객체 분리
보통 클라이언트 요청 폼에서 전달하는 데이터가 도메인 객체와 딱 맞지않아 사용  
폼 데이터 전달에 Item 도메인 사용루트  

    HTML form -> Item -> Controller -> Item -> Repository

폼 데이터 전달을 위한 별도의 객체 사용루트  

    HTML form -> ItemSaveForm -> Controller -> Item 생성 -> Repository
  
<br>
