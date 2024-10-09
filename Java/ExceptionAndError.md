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

````
Object : 예외도 객체, 모든 객체의 최상위 부모 객체

Throwable : 최상위 예외, 하위에 Exception, Error 존재

Error : 메모리 부족 또는 심각한 시스템 오류와 같이 어플리케이션에서 복구 불가한 시스템 예외(언체크 예외)
        어플리케이션 개발자가 이 예외를 잡으려고 해서는 안됨(try ~ catch (Throwable, Error) 금지)

Exception : 어플리케이션 로직에서 사용할 수 있는 실질적 최상위 예외
            그 하위 예외(SQLException, IOException)는 모두 컴파일러가 체크하는 체크 예외(RuntimeException 제외)

RuntimeException : 런타임에 발생하는 언체크 예외
                   NullPointerException, IllegalArgumentException 등 런타임 예외들이 속함
````
<br>

## 검사 예외(checked exception)
컴파일 단계에서 컴파일러가 체크  
Exception 하위 클래스 중 RuntimeException 제외한 예외  
처리하지 않는 경우 컴파일 오류 발생  
예외 발생시 트랜잭션 롤백하지 않음  
기본적으로 검사 예외 사용 권장  
비즈니스 로직상 의도적으로 던지는 예외에만 사용(예외를 잡아서 반드시 처리해야하는 경우 사용)  
  
<br>

## 비검사 예외(unchecked exception)
컴파일 단계가 아닌 실행 단계에서 발생  
예외 발생시 트랜잭션 롤백  

<br>

## 예외 포함 및 스택 트레이스
예외를 전환할 때는 꼭 기존 예외를 포함해야 스택 트레이스 정상 확인 가능(root cause 확인 불가)  
예외 발생 원인과 스택 트레이스를 정확히 알 수 없음, 전환된 예외까지만 스택 트레이스 확인가능  

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


