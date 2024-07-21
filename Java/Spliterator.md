## spliterator
분할할 수 있는 반복자라는 의미  
Iterator와 같이 요소 탐색 기능을 제공하지만 병렬 작업에 특화  
자바 8은 컨렉션 프레임워크에 포함된 모든 자료구조에 디폴트 Spliterator 구현 제공  
T는 탐색하는 요소의 형식  

````java
public interface Spliterator<T> {
    //요소를 하나씩 순차적으로 소비하면서 탐색해야할 요소가 남았는지 반환
    boolean tryAdvance(Consumer<? super T> action); 
    //Spliterator 일부 요소를 분할해서 두번째 객체 생성
    Spliterator<T> trySplit();
    //탐색해야할 요소 수 반환
    long estimateSize();
    //분할과정에 사용될 Spliterator 특성
    int characteristics();
}
````

<br>

## 분할 과정
재귀적으로 각각의 Spliterator의 trySplit() 메서드 호출  
trySplit() 메서드 반환값이 null인 경우 재귀 종료  
characteristics 메서드로 정의한 특성에 영향을 받음  
  
<br>

## characteristics
추상 메서드로 정의  
Spliterator 자체의 특성 집합을 포함하는 int 반환  
ORDERED : 리스트처럼 요소에 정해진 순서 존재  
DISTINCT : x, y 두 요소를 방문했을 경우 x.equals(y)는 항상 false  
SORTED : 탐색된 요소는 미리 정의된 정렬 순서를 따름  
SZIED : 크기가 알려진 소스로 생성했을 경우 estimateSize()는 정확한 값 반환  
NON-NULL : 탐색하는 모든 요소는 null 아님  
IMMUTABLE : 소스는 불변, 탐색하는 동안 요소 추가, 변경 및 삭제 불가능  
CONCURRENT : 동기화 없이 소스를 여러 스레드에서 동시에 변경 가능  
SUBSIZED : 분할되는 모든 Spliterator는 SIZED 특성 보유  

<br>

## 커스텀 spliterator
분할하는 위치에 따라 결과가 변활 수 있음  
병렬 스트림에도 동작하는 Spliterator를 위해 분할하는 방법 직접 구현  

````java
class WordCounterSpliterator implements Spliterator<Character> {
    private final String string;
    private int currentChar = 0;
    
    public WordCounterspliterator(String string) {
        this.string = string;
    }
    
    @Override
    public boolean tryAdvance(Consumer<? super Character> action) {
        action.accept(string.charAt(currentChar++));  //현재 문자 소비
        return currentChar < string.length();   //소비할 문자가 남았으면 true 반환
    }
    
    @Override
    public Spliterator<Character> tyrSplit() {
        int currentSize = string.length() - currentChar;
        if (currentSzie < 10) {
            return null;    //파싱할 문자열을 순차 처리 가능하면 null 반환
        }
        //파싱할 문자열의 중간을 분할 위치로 지정
        for (int splitPos = currentSize / 2 + currentChar; splitPos < string.length(); splitPos++) {
            //다음 공백이 나올 때까지 분할 위치 이동
            if (Character.isWhitespace(string.charAt(splitPos))) {
                //처음부터 분할 위치까지 문자열을 파싱할 새로운 객체 생성
                Spliterator<Character> spliterator = new WordCounterSpliterator(string.substring(currentChar, splitPos));
                //이 WordCounterSpliterator의 시작 위치를 분할 위치로 지정
                currentChar = splitPos;
                //공백을 찾았고 문자열 분리 후 루프 종료
                return spliterator;
            }
        }
        return null;
    }
    
    @Override
    public long estimateSize() {
        return string.length() - currentChar;
    }
    
    @Override
    public int characteristics() {
        return ORDERED + SIZED + SUBSIZED + NON-NULL + IMMUTABLE;
    }
}

private int countWords(Stream<Character> stream) {
    WordCounter wordCounter = stream.reduce(new WordCounter(0, true),
        WordCounter::accumulate,
        WordCounter::combine);
    return wordCounter.getCounter();
}

Spliterator<Character> spliterator = new WordCounterSpliterator(SENTENCE);
//두번째 불리언 인수는 병렬 스트림 생성 여부 지시
Stream<Character> stream = StreamSupport.stream(spliterator, true);
countWords(stream);
````

<br>
