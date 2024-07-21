## 함수 객체
함수 타입을 표현하는 추상 메서드 하나만 담은 인터페이스(또는 추상 클래스)의 인스턴스  
특정 함수나 동작을 나타냄  
이전의 함수 개체는 익명 클래스를 주로 사용  

````java
//이전의 익명 클래스 인스턴스를 이용한 함수 객체 생성 방식
Collection.sort(words, new Comparator<String>() {   //Comparactor 인터페이스가 정렬을 담당하는 추상 전략
    public int compare(String s1, String s2) {      //익명 클래스가 정렬하는 구체적인 전략 구현
        return Integer.compare(s1.length(), s2.length())
    }
});
````

<br>

## 람다식(lambda expression)
추상 메서드 하나만 가지는 인터페이스를 함수형 인터페이스로 인정  
함수형 인터페이스의 인스턴스를 람다식을 사용해서 구현  
반환값의 타입을 컴파일러가 문맥을 살펴 추론  
타입을 결정하지 못할 경우 개발자가 직접 명시  
타입을 명시해야 코드가 더 명확할 때를 제외하고 람다식 사용  
람다는 이름이 없고 문서화 불가, 코드 자체로 동작이 명확하지 않은 경우 부적합  
람다 크기는 한줄에서 세줄 사이가 적합  

````java
//람다식을 함수 객체로 사용 - 익명 클래스 대체
Collections.sort(words, 
        (s1, s2) -> Integer.compare(s1.length(), s2.length()));

//비교자 생성 메서드
Collections.sort(sords, comparingInt(String::length));

//List 인터페이스 sort 메서드 사용
words.sort(comnparingInt(String::length));

//함수 객체를 인스턴스 필드에 저장
public enum Operation {
    PLUS("+", (x, y) -> x + y),
    MINUS("-", (x, y) -> x - y),
    TIMES("*", (x, y) -> x * y),
    DIVIDE("/", (x, y) -> x / y);
    
    private final String symbol;
    private final DoubleBinaryOperator op;
    
    Operation(String symbol, DoubleBinaryOperaot op) {
        this.symbol = symbol;
        this.op = op;
    }
    
    @Override public String toString() { return symbol; }
    public double apply(double x, double y) {
        return op.applyAsDouble(x, y);
    }
}
````

<br>

