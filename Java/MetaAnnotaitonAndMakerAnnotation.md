## 명명 패턴
이전의 도구나 프레임워크가 특별히 취급하는 프로그램 요소에는 명명 패턴 사용  
어노테이션 사용보다 단점이 많음  

    1. 오타 발생 금지
    2. 올바른 프로그램 요소에서만 적용 보장 불가능
    3. 프로그램 요소를 매개변수로 전달 불가능

<br>

## 메타 어노테이션(meta-annotion)
어노테이션 선언에 다는 어노테이션  

````java
@Retention(RetentionPolicy.RUNTIME)   //런타임에도 유지되어야 함
@Target(ElementType.METHOD)           //반드시 메서드 선언에만 사용되어야 함
public @interface Test {
}
````

<br>

## 마커 어노테이션(marker-annotation)
아무 매개변수 없이 단순히 대상을 마킹  
어노테이션에 관심 있는 프로그램에 추가 정보 제공만  

````java
//마커 어노테이션 사용
public class Sample {
    @Test public static void m1() {}  //성공해야 함
    public static void m2() {}        //테스트 도구가 무시
    @Test public static void m3() {}
    public static void m4() {}
    @Test public void m5() {}         //잘못 사용한 예, 정적 메서드가 아님
    @Test public static void m6() {   //실패해야 함
        throw new RuntimeException("fail")
    }
}

//마커 어노테이션 처리 프로그램
public class RunTests {
    public static void main(String[] args) throws Exception {
        int test = 0;
        int passed = 0;
        Class<?> testClass = Class.forName(args[0]);
        for (Method m : testClass.getDeclaredMethods()) {
            if (m.isAnnotationPresent(Test.class)) {
                tests++;
                try {
                    m.invoke(null);
                    passed++;
                } catch (InvocationTargetException wrappedExc) {
                    Throwable exc = wrappedExc.getCause();
                    System.out.println(m + " 실패: " + exc);
                } catch (Exception exc) {
                    System.out.println("잘못 사용한 @Test: " + m);
                }
            }
        }
        System.out.printf("성공: %d, 실패: %d%n", passed, tests - passed);
    }
}
````

<br>

## 매개변수 어노테이션
매개변수를 받는 어노테이션  

````java
//매개변수 하나를 받는 어노테이션
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface ExceptionTest [
    Class<? extends Throwable> value();
}

//여러 매개변수를 받는 어노테이션
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface ExceptionTest [
    Class<? extends Throwable>[] value();
}

//반복 가능한 어노테이션
@Retemtion(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@Repeatable(ExceptionTestContainer.class)
public @interface ExceptionTest [
    Class<? extends Throwable> value();
}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface ExceptionTestContainer {  //컨테이너 어노테이션
    ExveptionTest[] value();
}

//매개변수 하나짜리 어노테이션을 사용한 프로그램
public class Sample2 {
    @ExceptionTest(ArithmeticException.class)
    public static void m1() {   //성공해야 함
        int i = 0;
        i = i / i;
    }
    @ExceptionTest(ArithmeticException.class)
    public static void m2() {   //실패해야 함(다른 예외 발생)
        int[] a = new int[0];
        int i = a[1];
    }
    @ExceptionTest(ArithmeticException.class)
    public static void m3() {}  //실패해야 함(예외 발생 안함)
}
````

<br>

## 마커 인터페이스
아무 메서드도 담고 있지 않고 단지 자신을 구현하는 클래스가 특정 속성을 가짐을 표시  
마커 어노테이션에 비해 구식이라는 인식이 있으나 장점이 존재  
마커 어노테이션은 마커 인터페이스에 비해 어노테이션 시스템의 많은 지원을 받음  
    
    1. 마커 인터페이스를 구현한 클래스의 인스턴스들을 구분하는 타입으로 사용가능  
      마커 인터페이스는 타입이므로 런타임이 아닌 컴파일 타임에 오류 발견 가능  
      
    2. 적용 대상을 정밀하게 지정 가능  
      마커 어노테이션 적용대상이 ElementType.TYPE인 경우 마커 인터페이스가 좀더 정밀할 가능성  

<br>

