## FieldError 생성자
ObjectError 생성자도 이와 유사  
objectName : 오류가 발생한 객체 이름  
field : 오류필드  
rejectedValue : 사용자가 입력한 값(거절된 값)  
bindingFailure : 타입 오류 같은 바인딩 실패와 검증 실패 구분값  
codes : 메시지 코드  
arguments : 메시지에서 사용하는 인자  
defaultMessage : 기본 오류 메시지  

````java
public FieldError(String objectName, String field, String defaultMessage);

public FieldError(String objectName, String field, 
    @Nullable Object rejectedValue, boolean bindingFailure, @Nullable String[] codes,
    @Nullable Object[] arguments, @Nullable String defaultMessage);
````

<br>

## 사용자 입력값 유지
@ModelAttribute 바인딩되는 시점에 오류발생시 모델 객체에 사용자 입력값을 유지하기 어려움  
FieldError 객체의 rejectedValue 변수를 통해 사용자 입력값 저장  
타임리프의 th:field는 정상 상황인 경우 모델 객체의 값을, 오류 상황인 경우 FieldError 객체의 값을 사용   
타입 오류로 인한 바인딩 실패시 FieldError 생성후 값을 저장하고 BindingResult에 담아 컨트롤러 호출  

<br>

## codes, arguments
codes는 String 배열, arguments는 Object 배열(순서대로 매칭해서 처음 매칭되는 메시지 사용)  
기본적으로 messages 파일 이외의 추가적인 파일사용시 설정필요  
    
    [application.properties]
      spring.messages.baasename=messages,errors

    [errors.properties]
      required.item.itemName=상춤이름은 필수입니다.
      range.item.price=가격은 {0} ~ {1} 까지 허용합니다.
      
    [.class]
      bindingResult.addError(
          new FieldError(objectName:"item", field:"price",
              item.getPrice(), bindingFailure:false,
              codes:new String[]{"range.item.price"},
              arguments:new Object[]{1000, 100000},
              defualtMessage:null));

<br>

## reject
컨트롤러에서 BindingResult 위치는 검증해야하는 객체인 target 바로 다음  
BindingResult는 본인이 검증해야할 객체인 target을 알고 있음  

````java
void rejectValue(@Nullable String field, String errorCode, @Nullable Object[] errorArgs, @Nullable String defaultMessage);
````

FieldError 객체 대신 rejectValue(), reject() 사용으로 검증 오류처리  
메시지 파일에서 errorCode + objectName + fieldName 순으로 메시지 매칭  
````java
bindingResult.rejectValue(field:"price", errorCode:"range",
    arguments:new Object[]{1000, 1000000}, 
    defaultMessage:null);
bindingResult.reject(field:"totalPriceMin",
    arguments:new Object[]{10000, resultPrice},
    defaultMessage:null);
````

<br>

## 오류 메시지
오류 메시지는 MessageCodesResolver를 통해 범용성 있게 만들거나 디테일하게 만들수 있다  
범용적으로 사용하다가 세밀하게 작성해야하는 경우 디테일한 메시지 사용(단계적 오류 메시지)  
객체명과 필드명을 조합한 세밀한 오류 메시지 존재시 errorCode만 있는 오류메시지보다 우선순위 높음  

    [errors.properties]
      required=필수값입니다.
      required.item.itemName=상품 이름은 필수입니다.
      range=허용범위에 속하지 않습니다.
      range.item.price=상품 가격이 허용범위에 속하지 않습니다.

<br>
