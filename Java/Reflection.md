## 리플렉션
클래스나 메서드의 메타정보를 동적으로 획득  
JDK 동적 프록시나 CGLIB 프록시 생성 오픈소스 기술의 핵심  
동적으로 유연함을 제공하지만 컴파일 시점에 오류를 잡지 못함  
일반적으로 사용하지 않지만 오픈소스나 프레임워크 개발에 사용  
클래스 인스턴스의 필드와 메서드를 접근 제어자와 상관없이 접근가능  
JVM 클래스 로더에서 클래스 파일에 대한 로딩후 해당 클래스 정보를 담은 Class 객체를 힙 영역에 저장  
new 키워드를 이용한 할당 방식과 차이 존재  

<br>

## 객체 리플렉션 방식
힙 영역에 로드된 클래스 타입의 객체를 가져오는 방식  

1. ClassName.class
  ````java
  Class<Member> memberClass = Member.class;
  ````

2. Instance.getClass()
  ````java
  Class<? extends Member> memberClass = member.getClass();
  ````

3. Class.forName("package.ClassName")
  ````java
  Class<?> memberClass = Class.forName("package.Member");
  ````

<br>

## 리플렉션 인스턴스 생성 방식
생성자 메서드 메타정보를 통해 객체 인스턴스 생성  

````java
Constructor<?> constructor = memberClass.getConstructor();
Object obj = constructor.newInstance(); //타입 변환 가능
````

<br>

## 리플렉션 객체 접근 방식
1. 필드 접근
    ````java
    Field[] fields = memberClass.getDeclaredFields();
    ````
    
2. 메서드 접근
    ````java
    Method method = memberClass.getDeclaredMethod("methodName");
    method.invoke(target);  //선택한 객체를 통해 메서드 실행
    ````

<br>

