## Http 메시지 컨버터
뷰 템플릿으로 생성한 HTML 파일로 응답하는 것이 아닌 JSON 데이터를 메시지 바디에서 직접 읽거나 쓰는 경우  
JsonConverter와 StringConverter로 구성  

@ResponseBody 어노테이션 사용한 경우

    기본 문자처리 : StringHttpMessageConverter
    기본 객체처리 : MappingJackson2HttpMessageConverter

인터페이스 : 'org.springframework.http.converter.HttpMessageConverter'
````java
public interface HttpMessageConverter<T> {
    boolean canRead(Class<?> clazz, @Nullable MediaTyp mediaType);
    boolean canWrite(Class<?> clazz, @Nullable MediaTyp mediaType);
    
    List<MediaType> getSupportedMediaTypes();
    
    T read(Class<? extends T> clazz, HttpInputMessage inputMessage)
            throws IOException, HttpMessageNotReadableException;
    void write(T t, @Nullable MediaType contentType, HttpOutputMessage outputMessage)
            throws IOException, HttpMessageNotWritableException;
}
````

<br>

## 메시지 컨버터 위치
요청 : @RequestBody 어노테이션과 HttpEntiity를 처리하는 ArgumentResolver에서 메시지 컨버터 호출  
응답 : @ResponseBody 어노테이션과 HttpEntiity를 처리하는 ReturnValueHandler에서 메시지 컨버터 호출  

<br>

## MVC Http 메시지 컨버터
HTTP 요청 : @RequestBody, HttpEntity(RequestEntity)  
HTTP 응답 : @ResponseBody, HttpEntity(ResponseEntity)  

<br>

## 메시지 컨버터 우선순위
````
0 = ByteArrayHttpMessageConverter
1 = StringHttpMessageConverter
2 = MappingJackson2HttpMessageConverter
````

<br>

## 메시지 컨버터 종류
### ByteArrayHttpMessageConverter 
````
byte[] 데이터 처리  
클래스 타입 : byte[]  
미디어 타입 : */*  
쓰기 미디어 타입 : application/octet-stream
````
    
### StringHttpMessageConverter
````
String 데이터 처리  
클래스 타입 : String  
미디어 타입 : */*  
쓰기 미디어 타입 : text/plain  
````

### MappingJackson2HttpMessageConverter
````
application/json  
클래스 타입 : 객체 또는 HashMap  
미디어 타입 : application/json  
쓰기 미디어 타입 : application/json  
````

<br>

## ArgumentResolver
어노테이션 기반 컨트롤러를 처리하는 RequestMappingHandlerAdaptor에서 호출  
핸들러가 필요로하는 다양한 파라미터 값을 생성  

````java
public interface HandlerMethodArgumentResolver {
    boolean supportsParameter(MethodParameter parameter);
    Object resolveArgument(MethodParameter parameter, ...)
        throws Exception;
}
````

<br>

## ReturnValueHandler
핸들러의 다양한 반환값을 변환하고 처리(ArgumentResolver와 유사)

````java
public interface HandlerMethodReturnValueHandler {
    boolean supportsReturnType(MethodParameter returnType);
    void handleReturnValue(@Nullable Object returnValue, ...)
        throws Exception;
}
````

<br>

## WebMvcConfigurer 확장

````java
@Bean
public WebMvcConfigurer webMvcConfigurer() {
    return new WebMvcConfigurer() {
        @Override
        public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) [
            ...
        }
        
        @Override
        public viod extendMessageConverters(List<HttpMessageConverter<?>> converters) {
            ...
        }
    };
}
````

<br>
