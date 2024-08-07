## 포크/조인 프레임워크
병렬화 가능한 작업을 재귀적으로 분할  
서브태스크 각각의 결과를 병합해서 전체 결과를 도출  
서브태스크를 스레드 풀(ForkJoinPool)의 작업자 스레드에 분산 할당하는 ExecutorService 인터페이스 구현  
일반적으로 ForkJoinPool은 싱글톤으로 사용  
인수가 없는 디폴트 생성자를 이용해서 모든 프로세서가 자유롭게 풀에 접근  
Runtime.availableProcessors 반환값으로 풀에 사용할 스레드 수   

<br>

## RecursiveTask
스레드 풀 이용을 위한 RecursiveTask<R> 서브클래스 생성 필수  
R은 병렬화된 태스크가 생성하는 결과 형식  
결과가 없는 경우(다른 비지역 구조를 변경 가능) RecursiveAction 형식  
RecursiveTask 정의시 추상 메서드 compute 구현 필수  

````java
//의사코드
protected abstract R compute() {
    if (태스크가 충분히 작거나 더 이상 분할 불가능) {
        순차적으로 태스크 계산
    } else {
        태스크를 두 서브태스크로 분할
        태스크가 다시 서브태스크로 분할되도록 이 메서드 재귀적 호출
        모든 서브태스크 연산이 완료될 때까지 대기
        각 서브태스크 결과 병합
    }
}

public class ForkJoinSumCalculator extends java.util.concurrent.Recursivetask<Long> {
    private final long[] numbers;
    priavte final int start;
    private final int end;
    public static final long THRESHOLD = 10_000;  //서브태스크 최대 갯수
    
    //메인 태스크 생성시 사용할 공개 생성자
    public ForkJoinSumCalculator(long[] numbers) {
        this(numbers, 0, numbers.length);
    }
    
    //메인 태스크의 서브태스크를 재귀적으로 생성하는 비공개 생성자
    private ForkJoinSumCalculator(long[] numbers, int start, int end) {
        this.numbers = numbers;
        this.start = start;
        this.end = end;
    }
    
    @Override
    protected Long compute() {
        int length = end - start;
        if (length <= THRESHOLD) {
            return computeSequentially();
        }
        ForkJoinSumCalculator leftTask = new ForkJoinSumCalculator(numbers, start, start + length / 2);
        leftTask.fork();  //ForkJoinPool 내의 다른 스레드로 새로 생성한 태스크를 비동기로 실행
        ForkJoinSumCalculator rightTask = new ForkJoinSumCalculator(numbers, start + length / 2, end);
        Long rightResult = rightTask.compute(); //두번째 서브태스크 동기 실행, 추가 분할 가능
        Long leftResult = leftTask.join();  //첫번째 서브태스크의 결과를 읽거나 결과 없을시 대기
        return leftResult + rightResult;
    }
    
    private long computeSequentially() {
        long sum = 0;
        for (int i = start; i < end; i++)
            sum += numbers[i];
        return sum;
    }
}

public static long forkJoinSum(long n) {
    long[] numbers = LongStream.reangeClosed(1, n).toArray();
    ForkJoinTask<Long> task = new ForkJoinsumCalculator(numbers);
    return new ForkJoinPool().invoke(task); //ForkJoinSumCalculator에서 정의한 태스크 결과 
}
````

<br>

## 포크/조인 프레임워크 사용법 
1. join 메서드를 태스크에 호출하면 결과가 준비될 때까지 호출자 블록  
    두 서브태스크가 모두 시작된 다음에 join 호출  

2. RecursiveTask 내에서는 ForkJoinPool의 invoke 메서드 사용 금지  
    대신 compute 또는 fork 메서드를 직접 호출 가능  
    순차 코드에서 병렬 계산을 하는 경우에만 invoke 사용  

3. 서브태스크에 fork 메서드를 호출해서 ForkJoinPool 일정 조절 가능  
    양쪽 작업 모두에 fork 메서드 호출보단 한쪽은 compute 메서드 호출하는 것이 효율적  
    두 서브태스크의 한 태스크에는 같은 스레드 재사용 가능  

4. 포크/조인 프레임워크를 이용하는 병렬 계산은 디버깅하기 어려움  
    fork 메서드는 다른 스레드에 compute 메서드 호출함으로 스택 트레이스로 문제 탐색 어려움  

5. 멀티코어에서 포크/조인 프레임워크가 순차보다 항상 효율적이지 않음  
    각 서브태스크의 실행시간은 새로운 태스크를 포킹하는데 드는 시간보다 길어야 효율적  

<br>

## 작업 훔치기(Work Stealing)
ForkJoinPool의 모든 스레드를 거의 공정하게 분할  
각각의 스레드는 자신에게 할당된 태스크를 포함하는 이중 연결 리스트를 참조  
작업이 끝날 때마다 큐의 헤드에서 다른 태스크를 가져와 작업 처리  
즉 할일이 끝난 스레드를 유휴 상태로 변경하는 것이 아닌 다른 스레드 큐의 꼬리 작업을 훔처서 실행  

<br>

