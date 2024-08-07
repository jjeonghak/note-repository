## 자바의 동시성
자바는 처음 릴리스된 시점부터 스레드, 동기화, wait/notify 같은 동시성 기능을 제공  
자바 5부터는 동시성 컬렉션 java.util.concurrent와 실행자(Excutor) 제공  
자바 7부터는 고성능 병렬 분해(parallel decom-position) 프레임워크 포크-조인(fork-join) 패키지 추가  
자바 8부터는 parallel 메서드를 통한 스트림 병렬 실행 지원  
동시성 프로그래밍은 안전성(safety)과 응답 가능(liveness) 상태를 유지하는 것이 필수  

<br>

## 병렬화 스트림
올바른 계산과 성능 향상이 보장되지 않은 경우 스트림 파이프라인에 병렬화 적용 금지  
데이터 소스가 Stream.iterate이거나 중간 연산으로 limit를 사용하면 파이프라인 병렬화로 성능 개선 불가  
대체로 참조 지역성(locality of reference)이 뛰어난 자료구조 사용시 병렬화 성능이 좋음  

    ArrayList, HashMap, HashSet, ConcurrentHashMap  
    배열, int, long  
  
종단 연산의 작업량이 파이프라인 전체 작업에서 상당한 비중이며 순차적인 연산이라면 병렬 성능 효과 제한  
종단 연산 중 축소(reduction)연산이 가장 병렬화 성능이 좋음  
  
    Stream의 reduce 메서드, min, max, count, sum      //파이프라인의 모든 원소를 하나로 합치는 연산  
    anyMatch, allMatch, noneMatch                   //조건에 맞으면 바로 값 반환하는 연산  
  
직접 구현한 Stream, Iterable, Collection이 병렬화의 이점을 누리려면 spliterator 재정의 필수  
스트림에 병렬화를 잘못 적용하면 응답 불가와 같이 성능이 나빠지거나 예상치 못한 동작 발생  

<br>

## 안전 실패(safety failure)
결과가 잘못되거나 오동작하는 것  
병렬화한 파이프라인이 사용하는 mappers, filters, 사용자 지정 함수 객체가 명세대로 동작하지 않는 경우 발생 가능  
안전 실패 방지를 위한 Stream 명세 규약    

    1. 결합 법칙 만족(associative)
    2. 간선 받지 않음(non-interfering)
    3. 무상태(stateless)

요구사항을 지키지 않은 스트림은 동작은 하지만 병렬화 적용시 안전 실패 발생  

````java
//소수 계산 스트림 파이프라인 - 병렬화에 적합
static long pi(long n) {
    return LongStream.rangeClosed(2, n)
        .parallel()                             //병렬화 이전보다 성능 향상
        .mapToObj(BigInteger::valueOf)
        .filter(i -> i.isProbablePrime(50))
        .count();
}
````

<br>

