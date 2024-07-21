## 병렬 스트림
parallelStream, parallel 메서드를 통해 병렬 스트림 생성 가능  
각각의 스레드에서 처리할 수 있도록 스트림 요소를 여허 청크로 분할한 스트림  
멀티코어 프로세서가 각각의 청크를 처리하도록 할장  
순차 스트림은 sequential 메서드 사용  

<br>

### 순차를 병렬로 변환
````java
public long parallelSum(long n) {
    return Stream.iterate(1L, i -> i + 1)
        .limit(n)
        .parallel()   //병렬 스트림으로 변환
        .reduce(0L, Long::sum);
}
````

### 최종적으로 호출된 순차 및 병렬 메서드가 전체 파이프라인에 영향
````java
stream.parallel()
    .filter(...)
    .sequential()
    .map(...)
    .parallel()
    .reduce();
````

<br>
  
## 병렬 스트림 스레드 풀 설정
병렬 스트림 작업은 내부적으로 ForkJoinPool 사용  
기본적으로 프로세서 수(Runtime.getRuntime().availableProcessors() 반환값)에 상응하는 스레드  
현재는 하나의 병렬 스트림에 사용할 수 있는 특정값 지정 불가  
특별한 이유 없다면 ForkJoinPool 기본값 사용 권장  

````java
//전역 설정 코드
System.setProperty("java.util.concurrent.ForkJoinPool.common.parallelism", "12");
````

<br>

## 잘못된 병렬 스트림
병렬 스트림의 잘못된 사용법은 공유된 상태를 변경하는 알고리즘에 사용  

````java
public long sideEffectSum(long n) {
    Accumulator accumulator = new Accumulator();
    LongStream.rangeClosed(1, n).parallel().forEach(accumulator::add);
    return accumulator.total;
}

//병렬 처리시 데이터 레이스 문제 발생
public class Accumulator {
    public long total = 0;  //여러 스레드에서 동시에 누적자 접근 및 변경
    pulbic void add(long value) { total += value; }
}
````

<br>

## 효과적 병렬 스트림
1. 확신이 없으면 직접 측정  
    언제나 병렬 스트림이 순차 스트림보다 효율적인 것은 아님  
    
2. 박싱 주의  
    자동 박싱과 언박싱은 성능에 크게 영향  
    기본형 특화 스트림 활용 검토  

3. 순차보다 병렬 성능이 떨어지는 연산 주의  
    limit, findFirst 메서드와 같이 요소의 순서에 의존하는 연산은 병렬 스트림에 취약  

4. 전체 파이프라인 연산 비용 고려  
    처리할 요소의 갯수가 n, 요소 하나 처리 비용 q라면 n * q로 예상 가능  
  
5. 소량의 데이터는 병렬 스트림이 비효율  
    소량의 데이터는 병렬화 과정에서 생기는 부가 비용을 상쇄할 이득이 발생하지 않음  

6. 스트림 구성 자료구조 검토
    ArrayList가 LinkedList보다 효율적으로 분해 가능  

7. 스트림 특성 및 파이프라인 중간 연산 특성 고려  
    SIZED 스트림은 같은 크기의 두 스트림으로 분할 가능, 효과적인 병렬 스트림 처리 가능  
    필터 연산은 스트림의 길이를 예측할 수 없음, 효과적인 병렬 처리 불가  

8. 최종 연산 병합 과정 비용 고려  
    서브스트림의 부분 결과 병합 과정 비용이 크면 병렬 스트림으로 얻은 성능 이익 상쇄 가능  

<br>
