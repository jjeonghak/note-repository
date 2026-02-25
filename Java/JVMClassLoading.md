# 클래스 로딩 메커니즘
자바 가상머신은 클래스를 설명하는 데이터를 클래스 파일로부터 메모리로 읽어들임  
그 데이터를 검증, 변환, 초기화하고 최종적으로 가상머신이 곧바로 사용 가능한 자바 타입을 생성  
자바 언어에서는 클래스 로딩, 링킹, 초기화가 모두 런타임에 이루어짐  
자바가 동적 확장 언어 기능을 제공 가능한 이유는 동적 로딩과 동적 링킹 덕분  

<br>

## 클래스 로딩 시점

<img width="500" height="200" alt="type_lifecycle" src="https://github.com/user-attachments/assets/4e2fa9fe-f861-4876-a6ab-e3d073d98c51" />

로딩, 검증, 초기화, 언로딩은 반드시 순서대로 진행  
반면 해석 단계는 초기화 후 시작 가능  
초기화 단계는 즉시 시작되어야 하는 상황을 엄격히 규정(능동 참조)  
- 바이트코드 명령어 `new`, `getstatic`, `putstatic`, `invokestatic` 만난 경우
- 리플렉션 메서드를 사용하는 경우
- 클래스 초기화시 상위 클래스가 초기화되지 않은 경우
- 메인 타입을 찾아 실행할때 초기화를 먼저 시작
- `java.lang.invoke.MethodHandle` 인스턴스를 호출할때 해당 클래스가 초기화되지 않은 경우
- 인터페이스 디폴트 메서드를 직간접적으로 구현한 클래스가 초기화될 때 인터페이스부터 초기화

<br>

반면 위의 여섯사지 상황이 아닌 타입 초기화를 촉발하지 않는 모든 참조 방식은 수동 참조  

```java
class SuperClass {
  static {
    System.out.println("super class init");
  }
  public static int value = 123;
}

class SubClass extends SuperClass {
  static {
    System.out.println("sub class init");
  }
}

public class NotInitialization_1 {
  public static void main(String[] args) {
    System.out.println(SubClass.value);  // "super class init"만 출력
  }
}

public class NotInitialization_2 {
  public static void main(String[] args) {
    SuperClass[] sca = new SuperClass[10];  // 아무것도 출력되지 않음
  }
}

class ConstClass {
  static {
    System.out.println("const class init");
  }
  public static final String HELLO_WORLD = "hello world";
}

public class NotInitialization_3 {
  public static void main(String[] args) {
    System.out.println(ConstClass.HELLO_WORLD); // "hello world"만 출력
  }
}
```

<br>

## 클래스 로딩 처리 과정

### 로딩
클래스 로딩의 전체 과정 중 한 단계  
자바 가상머신에 내장된 부트스트랩 클래스 로더 또는 사용자 정의 클래스 로더 사용 가능  
로딩 단계가 종료되면 바이너리 바이트 스트림은 메서드 영역에 저장  

1. 완전한 이름을 보고 해당 클래스를 정의하는 바이너리 바이트 스트림 로드
2. 바이트 스트림으로 표현된 정적인 저장 구조를 메서드 영역에서 사용하는 런타임 데이터 구조로 변환
3. 로딩 대상 클래스를 표현하는 `java.lang.Class` 객체를 힙 메모리에 생성

<br>

하지만 배열 클래스는 클래스 로더가 아닌 자바 가상머신이 직접 메모리에 동적으로 생성  
- 배열의 컴포넌트 타입이 참조 타입인 경우 재귀적으로 로딩 과정 수행해서 컴포넌트 타입 로딩
- 이때 배열 클래스는 컴포넌트 타입을 로드하는 클래스 로더의 이름 공간에 자리
- 배열의 컴포넌트 타입이 참조 타입이 아닌 경우(int[]) 자바 가상머신은 배열 클래스를 부트스트랩 클래스 로더에 위임
- 배열 클래스의 접근성은 해당 컴포넌트 타입과 동일

<br>

### 검증 
링킹 과정 중 첫번째 단계  
클래스 파일의 바이트 스트림에 담긴 정보가 규정한 모든 제약을 만족하는지 확인  
해당 정보를 코드로 변환해 실행할때 자바 가상머신 자체의 보안을 위협하지 않는지 확인  

1. 파일 형식 검증  
  바이트 스트림이 클래스 파일 형식에 부합하고 현재 버전의 가상머신에서 처리 가능한지  

    ```
    매직 넘버가 0xCAFEBASE로 시작하는가  
    메이저 버전과 마이너 버전 번호가 현재 자바 가상머신이 허용하는 범위인가  
    지원하지 않는 타입의 상수가 상수 풀에 들어있지 않은가  
    상수를 가리키는 다양한 인덱스 값 중 존재하지 않는 상수나 타입에 맞지 않는 상수를 가리키는 경우가 있나  
    CONSTANT_Utf8_info 타입 상수 중 utf-8 인코딩에 부합하지 않는 데이터는 없는가  
    클래스 파일 형식을 이루는 요소 중 일부 또는 파일 자체가 생략되었거나 추가된 정보가 있는가  
    ```

2. 메타데이터 검증  
  바이트코드로 설명된 정보의 의미를 분석하여 서술된 정보가 요구 사항을 충족하는지 확인  
  
    ```
    상위 클래스가 있는가  
    상위 클래스가 상속을 허용하는가(상위 클래스 `final` 여부)  
    상위 클래스 또는 인터페이스 필수 정의 메서드를 모두 구현했는가  
    필드와 메서드가 상위 클래스와 충돌하는가  
    ```

3. 바이트코드 검증  
  데이터 흐름과 제어 흐름을 분석하여 프로그램의 의미가 적법하고 논리적인지 확인  
  클래스의 메서드 본문인 클래스 파일의 Code 속성을 분석  

    ```
    피연산자 스택의 데이터 타입과 명령어 코드 시퀀스가 어울려 동작하는지  
    점프 명령어가 메서드 본문 밖의 바이트코드 명령어로 점프하는지  
    메서드 본문의 형 변환이 항상 유효한지  
    ```

4. 심벌 참조 검증  
  가상머신이 심벌 참조를 직접 참조로 변환할때 수행, 해당 변환은 링킹의 해석 단계에서 발생  
  현재 클래스가 참조하는 특정 외부 클래스, 메서드, 필드 등 접근할 권한이 있는지 확인  
  
    ```
    심벌 참조에서 문자열로 기술된 완전한 이름에 해당하는 클래스를 찾을 수 있는가
    단순 이름과 필드 서술자와 일치하는 메서드나 필드가 해당 클래스에 존재하는가
    심벌 참조가 가리키는 클래스, 필드, 메서드의 접근 지정자가 현재 클래스 접근을 허용하는가
    ```

<br>

### 준비
클래스 변수를 메모리에 할당하고 초기값을 설정하는 단계  
인스턴스 변수는 객체가 인스턴스화할때 객체와 함께 자바 힙에 할당  
클래스 변수에 할당하는 초기값은 해당 데이터 타입의 제로값  

<br>

```java
public static int value = 123;
```

준비 단계를 마친 직후 `value` 변수에 할당된 초기값은 `0`  
이후 `putstatic` 명령어는 클래스 생성자인 `<clinit>()` 메서드에 포함되며 이때 `123` 할당  

<br>

```java
public static final int value = 123;
```

클래스 필드의 필드 속성 테이블에 `ConstantValue` 속성이 존재하는 경우 준비 단계에서 바로 해당 값 할당  

<br>

### 해석
자바 가상머신이 상수 풀의 심벌 참조를 직접 참조로 대체하는 과정  
클래스 파일에서 `CONSTANT_Class_info`, `CONSTANT_Fieldref_info`, `CONSTANT_Methodref_info` 등이 심벌 참조  
심벌 참조란 대상을 명확하게 지칭하는데 이용 가능한 모든 형태의 리터럴  
직접 참조한 포인터, 상대적 위치 또는 대상의 위치를 간접적으로 가리키는 핸들  
즉 심벌 참조는 대상이 메모리에 로드되지 않아도 되며, 직접 참조는 필수적으로 메모리에 로드  

<br>

해석 단계를 수행하는 시간을 특정하지 않고 대신 심벌 참조를 다루는 바이트코드 명령어들데 해해 실행하도록 규정
메서드나 필드에 접근할 수 있는지 역시 해석 단계에서 확인  
동일한 심벌 참조에 대해서도 해석 요청이 여러 번 이루어지는게 보통, 첫번째 해석 결과를 캐시(`invokedynamic` 명령어 제외)  
해석을 반복해서 수행하더라도 자바 가상머신은 같은 대상에 대해서는 항상 같은 결과(멱등성 보장)  

<br>

단 `invokedynamic` 명령어는 해석된 심벌 참조를 다른 `invokedynamic`이 다시 요청한 경우 이전 해석과 다른 결과 반환 가능  
목적 자체가 동적 언어를 지원하는 것, 동적으로 계산된 호출 사이트 지정자  

<br>

### 초기화
자바 가상머신이 사용자 클래스에 작성된 자바 프로그램 코드를 실행하기 시작  
클래스 변수와 기타 자원을 개발자가 프로그램 코드에 기술한 대로 초기화  
클래스 생성자인 `<clinit>()` 메서드를 실행하는 단계  
해당 메서드는 자바 컴파일러가 자동으로 생성하는 메서드라서 개발자가 자바 코드로 직접 작성 불가  
모든 클래스 변수 할당과 정적 문장 블록의 내용을 취합하여 자동 생성  

```java
public class InvalidReference {
  static {
    // 나중에 정의된 변수에 값 할당 가능
    i = 0;

    // 정의되기 전 필드는 참고 불가능
    System.out.println(i);
  }
  static int i = 1;
}
```

<br>

가상머신 관점에서 인스턴스 생성자는 `<init>()`  
상위 클래스의 `<clinit>()`부터 실행되기 때문에 `java.lang.Object`의 메서드가 가장 먼저 실행  

```java
static class Parent {
  public static int a = 1;
  static {
    a = 2;
  }
}

static class Sub extends Parent {
  public static int b = a;
}

public static void main(String[] args) {
  System.out.println(Sub.b);  // 2 출력
}
```

<br>

정적 문장 블록이 없고 정적 변수에 초기값을 할당하지 않은 경우 컴파일러가 해당 메서드 생성하지 않을 가능성 존재  
인터페이스의 경우 정적 문장 블록은 사용 불가하지만 변수에 초기값 할당은 가능  
이때 부모 인터페이스의 메서드를 먼저 실행하지 않고, 해당 부모 인터페이스를 사용하는 시점에 비로소 초기화  

<br>

멀티 스레드 환경에서 `<clinit>()` 명령어는 동기화 필수  
오래 걸리는 작업이 포함된 경우 여러 스레드가 장시간 블록킹  

```java
/*
 * Thread[Thread-0,5,main] start
 * Thread[Thread-1,5,main] start
 * Thread[Thread-0,5,main] DeadLoopClass init
 */
static class DeadLoopClass {
  static {
    if (true) {
      System.out.println(Thread.currentThread() + " DeadLoopClass init");
      while (true) {}
    }
  }

  public static void main(String[] args) {
    Runnable script = new Runnable() {
      public void run() {
        System.out.println(Thread.currentThread() + " start");
        DeadLoopClass dlc = new DeadLoopClass();
        System.out.println(Thread.currentThread() + " end");
      }
    };
    Thread thread1 = new Thread(script);
    Thread thread2 = new Thread(script);
    thread1.start();
    thread2.start();
  }
}
```

<br>

## 클래스 로더
독립적인 클래스 이름 공간을 지니기 때문에 특정 클래스가 자바 가상머신에 유일한지 판단 가능  
동치 여부를 두 클래스가 모두 같은 클래스 로더로 로드됐는지로 판별  

```java
public class ClassLoaderTest {
  public static void main(String[] args) throws Exception {
    ClassLoader myLoader = new ClassLoader() {
      @Override
      public Class<?> loadClass(String name) throws ClassNotFoundException {
        try {
          String fileName = name.substring(name.lastIndexOf(".") + 1) + ".class";
          InputStream is = getClass().getResourceAsStream(fileName);
          if (is == null) {
            return super.loadClass(name);
          }
          byte[] b = new byte[is.available()];
          is.read(b);
          return defineClass(name, b, 0, b.length);
        } catch (IOException e) {
          throw new ClassNotFoundException(name);
        }
      }
    }
    Object obj = myLoader.loadClass("org.fenixsoft.jvm.ClassLoaderTest").newInstance();
    System.out.println(obj instanceof org.fenixsoft.jvm.ClassLoaderTest);  // false
  }
}
```

<br>

### 부모 위임 모델
자바 가상머신의 클래스 로더는 아래 두 종류 존재
- 자바 가상머신 자체의 일부인 부트스트랩 클래스 로더
- 추상 클래스 `java.lang.ClassLoader` 상속으로 구현된 클래스 로더, 가상머신 외부에 독립적으로 존재

<br>

JDK 8까지 유지된 3계층 클래스 로더와 부모 위임 모델을 통해 로드  

- 부트스트랩 클래스 로더  
  `JAVA_HOME/lib` 디렉토리에 위치한 파일들과 자바 가상머신이 클래스로 인식하는 파일들을 로드  
  해당 로더는 자바 프로그램에서 직접 참조 불가능  
  
- 확장 클래스 로더  
  `sun.misc.Launcher$ExtClassLoader`를 뜻함  
  `JAVA_HOME/lib/ext` 디렉토리에서 클래스로 인식하는 파일들을 로드  
  자바 코드로 구현되어 있어서 프로그램 안에서 직접 사용 가능  

- 애플리케이션 로더  
  `sun.misc.Launcher$AppClassLoader`를 뜻함  
  `ClassLoader` 클래스의 `getSystemClassLoader()` 메서드가 반환하는 클래스 로더  

<br>

<img width="500" height="250" alt="class_loader_and_parents_delegation_model" src="https://github.com/user-attachments/assets/efc80e69-6bde-40b7-ab2e-4657516b240e" />

부트스트랩 클래스 로더 외에는 부모가 필수로 존재  
클래스 로딩을 요청받은 클래스 로더는 수준에 맞는 상위 클래스 로더로 요청을 위임  
즉 프로그램이 아무리 많은 클래스 로더를 활용하더라도 Object 클래스는 모두 동일한 클래스(최상위 부트스트랩 클래스 로더)임이 보장  

```java
protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
  synchronized (getClassLoadingLock(name)) {
    Class<?> c = findLoadedClass(name);
    if (c == null) {
      try {
        if (parent != null) {
          c = parent.loadClass(name, false);
        } else {
          c = findBootstrapClassOrNull(name);
        }
      } catch (ClassNotFoundException e) {
        // 부모 클래스 로더 요청 실패
      }

      if (c == null) {
        // 부모 클래스 로더가 실패한 경우 직접 시도
        c = findClass(name);
      }
    }
    if (resolve) {
      resolveClass(c);
    }
    return c;
  }
}
```

<br>
















