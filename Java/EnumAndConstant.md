## 정수 열거 타입(int enum pattern)
타입 안전 보장 불가능, 표현력 저하  
동등 연산자 사용으로 컴파일 경고 없이 사용(원하는 비교 결과 아님, 엉뚱한 동작)  
평범한 상수 모음  

````java
public static final int APPLE_FUJI          = 0;
public static final int APPLE_PIPPIN        = 1;
public static final int APPLE_GRANNY_SMITH  = 2;

public static final int ORANGE_NAVEL    = 0;
public static final int ORANGE_TEMPLE   = 1;
public static final int ORANGE_BLOOD    = 2;

int i = (APPLE_FUJI - ORANGE_TEMPLE) / APPLE_PIPPIN;
````

<br>

## 열거 타입
일정 개수의 상수값 정의  
그 외의 값은 허용하지 않음  
다른 언어의 열거타입과 다르게 완전한 형태의 클래스  
상수 하나당 자신의 인스턴스를 하나씩 만들어 public static final 필드로 공개  
생성자를 제공하지 않으므로 클라이언트에 의해 인스턴스 직접 생성 방지 및 싱글톤 보장  
임의의 메서드나 필드 추가 가능  
근본적으로 불변(final)  
필요한 원소가 컴파일타임에 다 알 수 있는 상수 집합이라면 열거타입     

````java
public enum Apple   { FUJI, PIPPIN, GRANNY_SMITH }
public enum Orange  { NAVEL, TEMPLE, BLOOD }

public enum Planet {
    MERCURY (3.302e+23, 2.439e6),
    VENUS   (4.869e+24, 6.052e6),
    EARTH   (5.975e+24, 6.378e6),
    MARS    (6.419e+23, 3.393e6),
    JUPITER (1.899e+27, 7.149e7),
    SATURN  (5.685r+26, 6.027e7),
    URANUS  (8.683e+25, 2.556e7),
    NEPTUNE (1.024e+26, 2.477e7);
    
    private final double mass;            //질량(단위: kg)
    private final double radius;          //반지름(단위: m)
    private final double surfaceGravity;  //표면중력(단위: m / s^2)
    
    private static final double G = 6.67300E-11;    //중력상수(단위: m^3 / kg s^2)
    
    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
        surfaceGravity = G * mass / (radius * radius);
    }
    
    public double mass()            { return mass; }
    public double radius()          { return radius; }
    public double surfaceGravity()  { return surfaceGravity; }
    
    public double surfaceWeight(double mass) {
        return mass * surfaceGravity;   //F = ma
    }
}
````

<br>

## 상수별 클래스 몸체(constant-specific class body)
각 상수에서 자신에 맞게 메서드 재정의(상수별 메서드 구현, constant-specific method implementation)  

````java
public enum Operation {
    PLUS("+")    {public double apply(double x, bdouble y){return x + y;}},
    MINUS("-")   {public double apply(double x, bdouble y){return x - y;}},
    TIMES("*")   {public double apply(double x, bdouble y){return x * y;}},
    DIVIDE("/")  {public double apply(double x, bdouble y){return x / y;}};

    public abstract double apply(double x, double y);   //새로운 상수 추가시 추상 메서드 재정의 필수
    
    private final String symbol;
    Operation(String symbol){ this.symbol = symbol; }
    @Override public String toString() { return symbol; }
}
````

<br>

