## MessageCodesResolver
검증오류코드로 메시지 코드 생성  
MessageCodesResolver 인터페이스에 DefaultMessageCodesResolver 기본 구현체 사용  
주로 ObjectError, FieldError 객체와 함께 사용  

<br>

## DefaultMessageCodesResolver 기본 메시지 생성 규칙
객체 오류(ObjectError)

    errorCode + "." + objectName
    errorCode
    
필드 오류(fieldError)

    errorCode + "." + objectName + "." + field
    errorCode + "." + field
    errorCode + "." + fieldType
    errorCode
    
바인딩 오류(스프링 기본 오류 코드)

    typeMismatch + "." + objectName + "." + field
    typeMismatch + "." + field
    typeMismatch + "." + fieldType
    typeMismatch

<br>

## 동작 방식
rejectValue() 및 reject() 함수는 내부에서 MessageCodesResolver 사용  
MessageCodesResolver 내부에서 메시지 코드 생성  
FieldError 및 ObjectError 객체 생성자에 생성된 메시지 코드 배열 전달  
BindinfResult 로그를 통해 확인 가능  
타임리프 렌더링시 th:error 실행되면서 오류 존재시 오류 메시지 코드 순대로 탐색(해당 코드 없으면 default)  

````java
public class MessageCodesResolverTest {

  MessageCodesResolver codesResolver = new DefaultMessageCodesResolver();

  @Test
  void messageCodesResolverObject() {
      String[] messageCodes = codesResolver.resolveMessageCodes("required", "item");
      for (String messageCode : messageCodes) {
          System.out.println("messageCode = " + messageCode);
      }
  }

  @Test
  void messageCodesResolverField() {
      String[] messageCodes = codesResolver.resolveMessageCodes("required", "item", "itemName", String.class);
      for (String messageCode : messageCodes) {
          System.out.println("messageCode = " + messageCode);
      }
  }
}
````

<br>
