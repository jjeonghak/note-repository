## 열거형 인터페이스
타입 안전 열거 패턴(typesafe enum pattern)과는 다르게 열거 타입은 확장불가  
연산 코드(operation code, opcode)와 같은 열거타입은 확장성 필요  
열거 타입은 임의의 인터페이스 구현가능  
연산 코드용 인터페이스 작성 후 열거 타입을 통해 구현  
열거 타입이 아닌 클라이언트는 인터페이스를 사용  
인터페이스와 그 인터페이스를 구현하는 기본 열거 타입을 함께 사용해 똑같은 효과 가능  

````java
public interface Operation {
    double apply(double x, double y);
}

public enum BasicOperation implements Operation {
    PLUS("+") {
        public double apply(double x, double y) { return x + y; }
    },
    MINUS("-") {
        public double apply(double x, double y) { return x - y; }
    },
    TIMES("*") {
        public double apply(double x, double y) { return x * y; }
    },
    DIVIDE("/") {
        public double apply(double x, double y) { return x / y; }
    };
    
    private final String symbol;
    
    BasicOperation(String symbol)       { this.symbol = symbol; }
    @Override public String toString()  { return symbol; }
}
````
<br>

## 확장 가능 열거 타입
````java
public enum ExtendedOperation implemenbts Operation [
    EXP("^") {
        public double apply(double x, double y) { return Math.pow(x, y); }
    },
    REMAINDER("%") {
        public double apply(double x, double y) { return x % y; }
    };
    
    private final String symbol;
    
    ExtendedOperation(String symbol)    { this.symbol = symbol; }
    @Override public String toString()  { return symbol; }
}
````

<br>

## 클라이언트 사용
````java
public static void main(String[] args) {
    double x = Double.parseDouble(args[0]);
    double y = Double.parsedouble(args[1]);
    test(ExtendedOperation.class, x, y);
}

private static <T extneds Enum<T> & Operation> void test(   //Class 객체가 열거 타입인 동시에 Operation 하위 타입
        Class<T> opEnumType, double x, double y) {
    for (Operation op : opEnumType.getEnumConstatncs())
        System.out.printf("%f %s %f = %f%n", x, op, y, op.apply(x, y));
}
````

<br>
