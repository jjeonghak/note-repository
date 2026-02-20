# 가상머신 성능 모니터링
데이터는 근거가 되며 도구는 데이터를 처리하는 수단  
데이터는 예외 스택, 운영로그, 가비지 컬렉터 로그, 스레드 덤프 스냅샷, 힙 덤프 스냅샷 등을 포괄  

<br>

## 기본적인 문제 해결 도구
JDK `bin` 디렉토리에는 다양한 도구 존재  
대부분 크기가 20KB 내외로 그저 얇은 래퍼 형태의 명령 도구들, 실제 자바 코드는 JDK 도구 라이브러리에 담김  
- 상용 인증 도구: `JRockit`에서 유래한 운영 및 관리 통합 도구인 `JMC`, `JFR`가 여기 속함
- 공식 지원 도구: 장기간 지원되는 도구들로 JDK 버전 별 차이가 존재하지만 사라지지 않음
- 실험적 도구: 공식 지원되지 않으며 실험적인 도구

<br>

### jps: 가상머신 프로세스 상태 도구
동작 중인 가상머신 프로세스 목록을 보여주며 각 프로세스에서 가상머신이 실행한 메인 클래스 이름과 로컬 식별자 조회 가능  
대다수 다른 JDK 도구에서 모니터링할 가상머신 프로세스를 명시하려면 `LVMID`를 알아야해서 유용  

```
jps [options] [hostid]
```

```
$ jps -l
2388 D:\Develop\glassfish\bin\..\modules\admin-cli.jar
2764 com.sun.enterprise.glassfish.bootstrap.ASMain
3788 jdk.jcmd/sun.tools.jps.Jps
```

<br>

### jstat: 가상머신 통계 정보 모니터링 도구
프로세스 클래스 로딩, 메모리, 가비지 컬렉션, JIT 컴파일과 같은 런타임 데이터 조회 가능  

```
jstat [option vmid [interval[s|ms] [count]]]
```

<img width="600" height="150" alt="jstat_result" src="https://github.com/user-attachments/assets/39bb2fbe-ed5f-4c0a-92be-759e42b70dfd" />

```
$ jstat -gcutil 5404
S0    S1     E      O      M      CCS    YGT  YGCT   FGC  FGCT   CGC  CGCT   GCT
0.00  87.26  31.15  61.28  97.83  92.61  17   0.156  0    0.000  8    0.014  0.170
```

<br>

### jinfo: 자바 설정 정보 도구
가상머신의 다양한 매개변수를 실시간으로 조회 가능  

```
jinfo [options] vmid
```

```
$ jinfo -flag ConcGCThreads 1444
-XX:ConcGCThreads=2
```

<br>

### jmap: 자바 메모리 매핑 도구
힙 스냅샷을 파일로 덤프해주는 자바용 메모리 맵 명령어  

```
jmap [options] vmid
```

```
$ jmap -dump:format=b,file=jconsole.bin 15396
Dumping heap to C:\Users\IcyFenix\jconsole.bin ...
Heap dump file creted [12671288 bytes in 0.034 secs]
```

<br>

### jhat: 가상머신 힙 덤프 스냅샷 분석 도구
JDK 8까지 제공되던 JVM 힙 분석도구, JDK 9부터 jhsdb 사용  
웹 서버를 내장하고 있어서 분석이 완료되면 웹 브라우저로 결과 조회 가능  
직접 사용하는 일이 적음  
힙 스냅샷 덤프를 애플리케이션이 배포된 서버에서 직접 분석하는 일은 거의 없음  
분석 기능이 단순  

<img width="500" height="300" alt="jhat_result" src="https://github.com/user-attachments/assets/d883c6ab-b1cc-48ce-a9a8-6c7d449b63a0" />

```
$ jhat jconsole.bin
Reading from jconsole.bin...
Dump file created Fri Mar 31 19:55:11 KST 2023
Snapshot read, resolving...
Resolving 90565 objects...
Chasing references, expect 18 dots.................
Eliminating duplicate references.................
Snapshot resolved.
Started HTTP server on port 7000
Server is ready.
```

<br>

### jstack: 자바 스택 추적 도구
현재 가상머신의 스레드 스냅샷을 생성  
주로 스레드가 장시간 멈춰있는 경우 원인을 찾을때 사용  

```
jstack [options] vmid
```

```
$ jstack -l 3500
2023-03-30 10:42:55
Full thread dump OpenJDK 64-Bit Server VM (17.0.6+10 mixed mode):

Threads class SMR info:
_java_thread_list=0x00000245f39ee290, length-32, elements={...}

"main" #1 prio=6 os_prio=0 cpu=10750.00ms elapsed=7005.02s
    tid=0x00000245bf407880 nid=0x9ed0 runnable  [0x00000071910fe000]
    java.lang.Thread.State: RUNNABLE
...
```

<br>

## GUI 도구

### JHSDB: 서비스 에이전트 기반 디버깅 도구

| 기본도구 | JCMD | JHSDB |
|--|--|--|
| jps -lm | jcmd | N/A |
| jmap -dump <pid> | jcmd <pid> GC.heap_dump | jhsdb jamp -binaryheap |
| jmap -histo <pid> | jcmd <pid> GC.class_histogram | jhsdb jmap -histo |
| jstack <pid> | jcmd <pid> Thread.print | jhsdb jstack -locks |
| jinfo -sysprops <pid> | jcmd <pid> VM.system_properties | jhsdb info -sysprops |
| jinfo -flags <pid> | jcmd <pid> VM.flags | jhsdb jinfo --flags |

```java
/**
 * -Xmx10m -XX:+UseSerialGC -XX:-UseCompressedOops
 */
public class JHSDBTestCase {
  static class Test {
    static ObjectHolder staticObj = new ObjectHolder();
    ObjectHolder instanceObj = new ObjectHolder();

    void foo() {
      ObjectHolder localObj = new ObjectHolder();
      System.out.println("done");  // 중단점 설정
    }  
  }

  private static class ObjectHolder {}

  public static void main(String[] args) {
    Test test = new JHSDBTestCase.Test();
    test.foo();
  }
}
```

```
$ jps -l
24020 Eclipse
43208 jdk.jcmd/sun.tools.jps.Jps
22700 JVM/org.fenixsoft.jvm.chapter4.JHSDBTestCase

$ jhsdb hsdb --pid 22700
```

<br>

### JConsole: 자바 모니터링 및 관리 콘솔
JMX 기반 GUI 모니터링 및 관리 도구  
주로 정보 수집 및 JMX MBean을 통해 시스템의 매개 변수값을 동적으로 조정하는데 사용  
`JDk/bin` 디렉토리의 `jconsole.exe` 실행  
메인화면은 Overview, Memory, Threads, Classes, VM Summary, MBeans 6개 탭으로 구성  

<img width="600" height="400" alt="jconsole_result" src="https://github.com/user-attachments/assets/e0ab0dba-02ae-495f-a4df-8a822ef8664d" />

<img width="600" height="400" alt="jconsole_monitoring_test" src="https://github.com/user-attachments/assets/796548ca-795d-46ff-838f-d41f38dc197c" />

```java
/**
 * -XX:+UseSerialGC -Xms100m -Xmx100m
 */
public class MemoryMonitoringTest {
  // 메모리 영역 확보 객체(placeholder), OOMObject 크기는 약 64KB
  static class OOMObject {
    public byte[] placeholder = new byte[64 * 1024];
  }

  public static void fillHeap(int num) throws InterruptedException {
    List<OOMObject> list = new ArrayList<OOMObject>();
    for (int i = 0; i < num; i++) {
      Thread.sleep(50);
      list.add(new OOMObject());
    }
    System.gc();
  }

  public static void main(String[] args) throws Exception {
    fillHeap(1000);
    while (true) {
      System.out.println("start pending");
      Thread.sleep(1000);
    }
  }
}
```

<br>

Memory 탭이 jstat GUI 버전이였다면, Thread 탭은 jstack GUI 버전  
스레드가 정지된 상황이라면 이 탭의 기능을 사용해서 분석 가능  

```java
public class ThreadMonitoringTest {
  // 무한 루프 스레드
  public static void createBusyThread() {
    Thread thread = new Thread(new Runnable() {
      @Override
      public void run() {
        while (true);
      }
    }, "testBusyThread");
    thread.start();
  }

  // 락을 대기하는 스레드
  public static void createLockThread(final Object lock) {
    Thread thread = new Thread(new Runnable() {
      @Override
      public void run() {
        synchronized (lock) {
          try {
            lock.wait();
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    }, "testLockThread");
    thread.start();
  }

  public static void main(String[] args) throws Exception {
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));

    br.readLine();
    createBusyThread();

    br.readLine();
    Object obj = new Object();
    createLockThread(obj);
  }
}
```

```java
public class DeadLockMonitoringTest {
  static class SynAddRunnable implements Runnable {
    int a, b;
    public SynAddRunnable(int a, int b) {
      this.a = a;
      this.b = b;
    }

    @Override
    public void run() {
      synchronized (Integer.valueOf(a)) {
        synchronized (Integer.valueOf(b)) {
          System.out.println(a + b);
        }
      }
    }
  }

  public static void main(String[] args) {
    // Integer.valueOf() 메서드의 -128 ~ 127 사이값 캐시를 이용한 교착상태 생성
    for (int i = 0; i < 100; i++) {
      // 1 + 2
      new Thread(new SynAddRunnable(1, 2)).start();
      // 2 + 1
      new Thread(new SynAddRunnable(2, 1)).start();
    }
  }
}
```

<br>

### VisualVM: 다용도 문제 대응 도구
일반적인 운영 및 문제 대응 기능에 더해 성능 분석까지 제공  
모니터링 대상 프로그램에 특별한 에이전트 소프트웨어를 심지 않아도 돼서 활용하기 쉽움  
넷빈즈 플랫폼을 기초로 다양한 플러그인 제공  

<br>

BTrace는 플러그인이자 독립적으로 사용 가능  
핫스팟 가상머신의 인스트루먼트 기능(로딩되어 동작중인 코드를 런타임에 갱신)을 이용해서 디버깅 코드 동적 삽입 가능  
프로그램 동작에 간섭하지 않기 때문에 운영중인 프로그램에 매우 유용  
동작중인 애플리케이션 우클릭 후 `Trace Application` 클릭  

```java
public class BTraceTest {
  public int add(int a, int b) {
    return a + b;
  }

  public static void main(String[] args) throws IOException {
    BTraceTest test = new BTraceTest();
    BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
    for (int i = 0; i < 10; i++) {
      reader.readLine();
      int a = (int) Math.round(Math.random() * 1000);
      int b = (int) Math.round(Math.random() * 1000);
      System.out.println(test.add(a, b));
    }
  }
}
```

```java
/* BTrace Script Template */
import org.openjdk.btrace.core.annotations.*;
import static org.openjdk.btrace.core.BTraceUtils.*;

@BTrace
public class TracingScript {
	/* put your code here */
  @OnMethod(
    clazz="BTraceTest",
    method="add",
    location=@Location(Kind.RETURN)
  )
  public static void func(@Self BTraceTest instance, int a, int b, @Return int result) {
    println("call stack:");
    jstack();
    println(strcat("method parameter A:", str(a)));
    println(strcat("method parameter B:", str(b)));
    println(strcat("method result:", str(result)));
  }
}
```

<br>
