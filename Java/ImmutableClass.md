## 불변클래스
인스턴스의 내부 값을 수정할 수 없는 클래스  
가변클래스보다 비교적 안전 및 사용성  
피연산자에 함수를 적용해서 결과를 반환하지만 피연산자의 상태변화는 없는 함수형 프로그래밍  
반면 함수를 적용해서 피연산자의 상태를 변경하는 절차적 혹은 명령형 프로그래밍은 불변클래스로 적합하지 않음  
스레드 안전하여 따로 동기화할 필요없음(그 어떤 스레드도 다른 스레드에게 영향을 끼칠 수 없음)  
값이 다르면 반드시 독립된 객체로 생성  
String, 기본타입의 박싱 클래스, BigInteger, BigDecimal 등  

<br>

## 불변클래스 생성 규칙
1. 객체의 상태를 변경하는 메서드(변경자) 제공금지  
2. 클래스 확장 가능성 제거  
3. 모든 필드 final 선언  
4. 모든 필드 private 선언  
5. 자신 이외에는 내부의 가변 컴포넌트 접근 가능성 제거  

````java
//불변 복소수 클래스
public final class Complex {
    private final double re;
    private final double im;
    
    //자주 사용되는 인스턴스 캐싱, 중복 인스턴스 생성방지(정적 팩토리)
    public static final Complex ZERO  = new Complex(0, 0);
    public static final Complex ONE   = new Complex(1, 0);
    public static final Complex I     = new Complex(0, 1);
    
    private Complex(double re, double im) {
        this.re = re;
        this.im = im;
    }
    
    //생성자 대신 정적 팩토리 사용
    public static Complex valueOf(double re, double im) {
        return new Complex(re, im);
    }
    
    public double realPart()        { return re;}
    public double imaginaryOart()   { return im; }
    
    //피연산자에 함수를 적용해서 결과를 반환
    //메서드 이름은 동사(add) 대신 전치사(plus)를 사용
    public Complex plus(Complex c) {
        return new Complex(re + c.re, im + c.im);
    }
    
    ...
    
    @Override public boolean equals(Object o) {
        if (o == this)
            return true;
        if (!(o instanceof Complex))
            return false;
        Complex c = (Complex) o;
        return Double.compare(c.re, re) == 0 && Double.compare(c.im, im) == 0;
    }
    
    @Override public int hashCode() {
        return 31 * Double.hashCode(re) + Double.hashCode(im);
    }
    
    @Override public String toString() {
        return "(" + re + " + " + im + "i)";
    }
}
````

<br>

