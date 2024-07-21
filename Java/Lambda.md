## 람다 표현식
메서드로 전달할 수 있는 익명 함수를 단순화한 것  
파라미터 리스트, 바디, 반환 형식, 예외 리스트 소유 가능  
람다 미적분학 학계에서 개발한 시스템에서 유래  
하나의 추상 메서드를 갖는 함수형 인터페이스(@FunctionalInterface)에 람다 표현식 사용 가능  

1. 익명 : 보통의 메서드와 달리 이름이 없으므로 익명으로 표현  
2. 함수 : 특정 클래스에 종속되지 않으므로 메서드와 달리 함수로 칭함  
3. 전달 : 메서드 인수로 전달하거나 변수로 저장 가능  
4. 간결성 : 익명 클래스와 달리 불필요한 코드 구현할 필요 없음  

<br>

## 람다 형식
1. 파라미터 리스트 : 람다 함수에 필요한 파라미터  
2. 화살표 : 람다의 파라미터 리스트와 바디 구분  
3. 람다 바디 : 람다의 반환값에 해당하는 표현식  

````java
Comparator<Apple> byWeight = 
    (Apple a1, Apple a2) -> a1.getWeight().compareTo(a2.getWeight());
````

<br>

## 람다 문법
1. 표현식(expression style) : (parameters) -&gt; expression  
2. 블록(block style) : (parameters) -&gt; { statements; }  


## 람다 활용
1. 불리언 표현식 : (List<String> list) -&gt; list.isEmpty()  
2. 객체 생성 : () -&gt; new Apple();  
3. 객체에서 소비 : (Apple a) -&gt; { System.out.println(a.getWeight()); }  
4. 객체에서 선택/추출 : (String s) -&gt; s.length()  
5. 두 값 조합 : (int a, int b) -&gt; a * b  
6. 두 값 비교 : (Apple a1, Apple a2) -&gt; a1.getWeight().compareTo(a2.getWeight())  

<br>

## 실행 어라운드 패턴(execute around pattern)
초기화/준비 코드(설정)와 정리/마무리 코드(정리)가 작업을 감싸고 있는 패턴

````java
//첫번째 단계
public String processFile() throws IOException {
    try (BufferedReader br = new BufferedReader(new FileReader("data.txt"))) {
        return br.readLine(); //실제 필요한 작업
    }
}

//두번째 단계
public interface BufferedReaderProccessor {
    String process(BufferedReader b) throws IOException;
}

//세번째 단계
public String processFile(BufferedReaderProcessor p) throws IOException {
    try (BufferedReader br = new BufferedReader(new FileReader("data.txt"))) {
        return p.process(br);
    }
}

//네번째 단계
String oneLine = processFile((BufferedReader br) -> br.readLine());
String twoLines = processFile((BufferedReader br) -> br.readLine() + br.readLine());
````

<br>

## 람다 형식 검사
람다가 사용된 콘텍스트를 이용해서 람다의 형식 추론 가능  
대상 형식(target type) : 콘텍스트에서 기대되는 람다 표현식의 형식  
    
1. 콘텍스트 정의 확인
    ````java
    filter(inventory, (Apple a) -> a.getWeight() > 150);
    ````

<br>

2. 대상 형식 확인
    ````java
    filter(List<Apple> inventory, Predicate<Apple> p)
    ````
<br>

3. 추상 메서드 확인
    ````java
    boolean test(Apple apple)
    ````

<br>

4. 람다 형식 확인
    ````java
    Apple -> boolean
    ````

<br>

## void 호환 규칙
람다의 바디에 일반 표현식이 존재하면 void를 반환하는 함수 디스크립터와 호환  

````java
//Predicate는 boolean 반환값
Predicate<String> p = s -> list.add(s);
//Consumer는 void 반환값
Consumer<String> b = s -> list.add(s);
````

<br>

## 람다 캡처링(capturing lambda)
익명 함수가 자유 변수(외부 정의 변수)를 활용하는 것처럼 람다에서도 사용 가능  
인스턴스 변수와 정적 변수를 자유롭게 사용 가능  
지역 변수는 명시적으로 final 한정자 선언 또는 final과 같은 방식으로 사용되어야함  
자유 지역 변수의 복사본을 제공, 복사본의 값이 변경되지 않도록 제약  
변수를 할당한 스레드 종료 후 람다를 실행한 스레드에서 해당 변수에 접근할 가능성  

````java
//컴파일 오류
int printNumber = 0;
Runnable r = () -> System.out.println(printNumber);
printNumber = 1;  //람다 참조 변수는 final 변수와 같은 동작 필수
````

<br>

