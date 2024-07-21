## 예외 번역
하위 계층의 예외를 예방하거나 스스로 처리할 수 없고 그 예외를 상위 계층에 노출하기 곤란한 경우 사용  
상위 계층에서 저수준 예외를 잡아 자신의 추상화 수준에 맞는 예외로 변경  
메서드는 저수준 예외를 처리해서 메서드에 맞는 예외를 전파  
그렇지 않을 경우 내부 구현 방식을 드러내며 윗 레벨 API 오염  

````java
/**
 * 이 리스트 안의 지정한 위치의 원소를 반환한다.
 * @throws IndexOutOfBoundsException index가 범위 밖이라면,
 *         즉 ({@code index < 0 || index >= size()})이면 발생한다.
 */
public E get(int index) {
    ListIterator<E> i = listIterator(index);
    try {
        return i.next();
    } catch (NoSuchElementException e) {
        throw new IndexOutOfBoundsExcepiton("index: " + index);
    }
}
````

<br>

## 예외 연쇄(exception chaining)
저수준 예외가 디버깅에 도움이 되는 경우 사용  
근본 원인(cause)인 저수준 예외를 고수준 예외에 실어 보내는 방식  
별도의 접근자 메서드(Theowable.getCause())를 통해 필요시 저수준 예외 탐색가능  
고수준 예외의 생성자는 상위 클래스의 생성자에 원인을 건내주어 최종적으로 Throwable 생성자까지 전달  

````java
try {
    ...
} catch (LowerLevelException cause) {
    //저수준 예외를 고수준 예외에 실어 보냄
    throw new HigherLevelException(cause);
}

class HigherLevelException extends Exception {
    HigherLevelException(Throwable cause) {
        super(cause);
    }
}
````

<br>

