## 예외 및 에러
에러 : 프로그램이 복구될 수 없는 오류  
예외 : 프로그래머가 직접 예측하고 막을 수 있는 오류  
Exception, RuntimeException, Throwable, Error 객체는 직접 사용 금지  
예외는 직렬화 가능  

<br>

## 계층 구조

````
  Object
   ㄴThrowable                     //Checked
     ㄴError                       //Unchecked
       ㄴThreadDeath
       ㄴIOError
       ㄴVirtualMachineError
         ㄴOutOfMemoryError
         ㄴStackOverflowError
     ㄴException                   //Checked
       ㄴIOException
       ㄴFileNotFoundException
       ㄴRuntimeException          //Unchecked
         ㄴNullPointerException
         ㄴNoSuchElementException
         ㄴBufferOverflowException
       ㄴ...
````

<br>

## 검사 예외(checked exception)
컴파일 단계에서 컴파일러가 체크  
Exception 하위 클래스 중 RuntimeException 제외한 예외  
처리하지 않는 경우 컴파일 오류 발생  
예외 발생시 트랜잭션 롤백하지 않음  
  
<br>

## 비검사 예외(unchecked exception)
컴파일 단계가 아닌 실행 단계에서 발생  
예외 발생시 트랜잭션 롤백  

<br>

## 표준 예외
1. IllegalArgumentException  
    호출자가 인수로 부적절한 값을 넘기는 경우 사용(null은 따로 취급)
    IllegalStateException과 비교했을때 인수 값이 무엇이든지 어차피 실패할 경우 사용
  
2. IllegalStateException  
    대상 객체의 상태가 호출된 메서드를 수행하기에 적합하지 않는 경우 사용
    
3. NullPointerException  
    null 값을 허용하지 않는 메서드에 null 값을 넘기는 경우 사용

4. IndexOutOfBoundException  
    어떤 시퀀스의 허용 범위를 넘는 값을 넘기는 경우 사용
    
5. ConcurrentModificationException  
    단일 스레드에서 사용하기 위한 객체를 여러 스레드에서 변경하는 경우 사용

6. UnsupportedOperationException  
    클라이언트가 요청한 동작을 대상 객체가 지원하지 않는 경우 사용

7. ArithmeticException, NumberFormatException  
    복소수나 유리수를 다루는 경우 사용

<br>


