## 파라미터
기본적으로 Http 요청 쿼리 스트링은 모두 문자로 처리
````java
String data = request.getParameter("data");
````

스프링은 타입 컨버터를 이용해서 타입변환 기능제공
````java
@RequestParam Integer data
@ModelAttribute UserData data
@PathVariable("data") Integer data
````

<br>

## 컨버터
사용자 지정으로 새로운 타입을 만들어서 변환할 수 있도록 확장 가능한 컨버터 인터페이스 제공  
과거에는 PropertyEditor를 이용해서 타입 변환하였으나 동시성 문제 존재로 인해 컨버터 등장  
인터페이스 구현시 Converter라는 이름의 인터페이스가 많이 존재하므로 주의필요  

[org.springframework.core.convert.converter.Converter]
````java
    public interface Converter<S, T> {
        T convert(S source);
        //S 타입으로 파라미터를 받고 T 타입으로 타입 변환후 반환
    }
````

<br>

## 용도에 따라서 다양한 방식의 타입 컨버터 제공
Converter : 기본 타입 컨버터  
ConverterFactory : 전체 클래스 계층 구조가 필요한 경우  
GenericConverter : 정교한 구현, 대상 필드의 어노테이션 정보 사용 가능  
ConditionalGenericConverter : 특정 조건이 참인 경우에만 실행  

<br>

## 컨버전 서비스
개별 컨버터를 모아두고 그것들을 묶어서 사용할 수 있는 기능 제공  
컨버전 서비스는 컨버팅 가능여부와 컨버팅 기능 제공  
메시지 컨버터(HttpMessageConverter)에는 적용되지 않음(json 객체의 경우 해당 라이브터리 참고)  

````java
public interface ConversionService {
    boolean canConvert(@Nullable Class<?> sourceType, Class<?> targetType);
    boolean canConvert(@Nullable TypeDescriptor sourceType, TypeDescriptor targetType);
    
    <T> T convert(@Nullable Object source, Class<T> targetType);
    Object convert(@Nullable Object source, @Nullable TypeDescriptor TypeDescriptor sourceType, 
        TypeDescriptor targetType);
}
````

<br>

### DefaultConversionService는 다음 두가지 인터페이스를 상속

ConversionService : 컨버터 사용로직  
ConverterRegistry : 컨버터 등록로직  

````java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverter(new StringToIpPortConverter());
        registry.addConverter(new IntegerToStringConverter());
        registry.addConverter(new StringToIpPortConverter());
        registry.addConverter(new IpPortToStringConverter());
    }
}
````

<br>

## 뷰 템플릿
객체를 문자로 변환하여 뷰 템플릿에 컨버터 적용가능  
변수 표현식(또는 th:value 사용)의 객체 출력인 경우 기본적으로 toString() 호출  
컨버전 서비스(또는 th:field 사용)는 컨버터 적용후 문자열 출력  
    
    변수 표현식(th:value) : ${...}
    컨버전 서비스(th:field) : ${{...}}
  
[HTML]
````html
th:text="${data}" 
th:text="${{data}}"
    
th:value="*{data}"
th:filed="*{data}"
````

<br>

