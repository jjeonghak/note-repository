## 가변인수 메서드
메서드의 넘기는 인수의 개수를 클라이언트가 조절  
가변인수 메서드 호출시 가변인수를 담기위한 배열 생성  
배열이 클라이언트에 노출되는 문제 발생  
제네릭과 매개변수화 타입 같은 실체화 불가 타입 사용시 컴파일 경고 발생  
제네릭 가변인수 배열 매개변수에 값을 저장하는 것은 안전하지 않음  

````java
static void dangerous(List<String>... stringLists) {
    List<Integer> intList = List.of(42);
    Object[] objects = stringLists;
    objects[0] = intList;                   //힙 오염 발생, 참조 발생
    String s = stringLists[0].get(0);       //ClassCastException
}
````

<br>

## 자바 라이브러리 제네릭 가변인수 메서드
타입 안전성을 검증한 자바 라이브러리 메서드  
실무에 굉장히 유용하므로 예외적으로 모순 수용한 메서드  

````java
Arrays.asList(T... a)
Collections.addAll(Collection<? super T> c, T... elements)
EnumSet.of(E first, E... rest)
````

<br>

## 제네릭 가변인수 안정성
메서드 작성자가 타입 안전성을 보장하는 경우 @SafeVarargs 어노테이션 사용  
순수하게 참조 및 상태 변화없이 인수들만 전달한다면 타입 안전성 보장  
전달만 한다고 항상 안전성 보장 불가  
제네릭 가변인수 배열을 다른 메서드가 접근하로록 허용하면 안전성 보장 불가  

````java
//자신의 제네릭 매개변수 배열 참조를 노출
static <T> T[] toArray(T... args) {
    return args;            //힘 오염을 메서드 호출한 콜스택으로 전이
}

static <T> T[] pickTwo(T a, T b, T c) {
    switch(ThreadLocalRandom.current().nextInt(3)) {
        case 0: return toArray(a, b);           //제네릭 가변인수를 받는 메서드
        case 1: return toArray(a, c);
        case 2: return toArray(b, c);
    }
    throws new AssertionError();                //도달할 수 없음
}

String[] attributes = pickTwo("a", "b", "c");   //ClassCastException(Object[] -> String[])
````

<br>

## 제네릭 가변인수 사용규약
1. 가변인수 배열에 아무것도 저장하지 않는다  
2. 배열의 원본 또는 복제본을 신뢰할 수 없는 코드에 노출하지 않는다  
3. 가능한 가변인수 배열보단 리스트 형태로 대체한다  

<br>

