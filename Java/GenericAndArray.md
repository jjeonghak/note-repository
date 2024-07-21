## 배열과 제네릭 차이
1. 공변  
    배열(공변) : Sub가 Super의 하위 타입이라면 배열 Sub[]는 배열 Super[]의 하위 타입  
    제네릭(불공변) : 서로 다른 Type1, Type2에 대해 List<Type1>과 List<Type2>는 아무 관계없음  

   ````java  
   Object[] objectArray = new Long[1];              //호환 가능
   List<Object> objectList = new ArrayList<Long>;   //호환 불가능
   ````

<br>

2. 실체화(reify)  
    배열(실체화) : 런타임에도 자신이 담기로 한 원소의 타입을 인지하고 확인  
    제네릭(실체화 불가 타입) : 타입 정보가 런타임에는 소거, 컴파일타임에만 검사, 제네릭 타입, 매개변수화 타입, 타입 매개변수로 사용 불가능  

      ````java
      //경고 및 안전성 취약
      Object[] o = new List<E>[];
      Object[] o = new List<String>[];
      Object[] o = new E[];
      ````

<br>

## 배열 제네릭 변환
E와 같이 실체화 불가 타입으로 배열 생성 불가능  
  
1. Object[]을 이용한 제네릭 배열 생성 우회방식  
    타입 안전한지 컴파일러는 알 방법이 없으므로, 개발자가 비검사 형변환 안전성을 판단  
    비검사 형변환 안전성 판단후 @SuppressWarnings 어노테이션을 이용해서 경고차단  

      ````java
      private E[] elements;
      elements = new E[DEFAULT_INITIAL_CAPACITY];              //컴파일 오류, generic array creation
      elements = (E[]) new Object[DEFAULT_INITIAL_CAPACITY];   //경고, unchecked cast
      ````

<br>

2. E[] 대신 Object[] 사용  
    원소에 접근할 때마다 형변환 필요  
    런타임 타입이 컴파일타임 타입과 달라 발생하는 힙 오염(heap pollution) 예방  

   ````java
   private Object[] elements;
   E result = elements[--size]           //컴파일 오류, incompatible types
   E result = (E) elements[--size];      //경고, unchecked cast
   ````

 <br>




