## lombok
Java 라이브러리  
Annotation을 사용해서 자동으로 메서드 작성  

<br>
  
## lombok 라이브러리 추가  
````java
compileOnly 'org.projectlombok:lombok'
annotationProcessor 'org.projectlombok:lombok'
testCompileOnly 'org.projectlombok:lombok'
testAnnotationProcessor 'org.projectlobok:lombok'
````

<br>

## 사용법
1. @Getter  
      get() 메서드 생성
      
2. @Setter  
      set() 메서드 생성
    
3. @NonNull  
      메서드나 생성자의 매개변수에 어노테이션 추가시 널체크
  
4. @ToString  
      toString() 메서드 생성
  
5. @EqualsAndHashCode  
      equals(Object other)과 hashCode() 생성
  
6. @NoArgsConstructor  
      매개변수 없는 생성자 생성, 불가능하면 컴파일 에러

7. @AllArgsConstructor  
      모든 필드에 대한 생성자 생성
  
8. @RequiredArgsConstructor  
      초기화되지 않은 모든 final 필드와 @NonUll 필드에 대한 생성자 생성
  
<br>

  
