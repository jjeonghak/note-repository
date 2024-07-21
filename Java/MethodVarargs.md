## 가변인수 메서드
명시한 타입의 인수를 0개 이상 받을 수 있는 메서드  
호출한 경우 가장 먼저 인수의 개수와 길이가 같은 배열 생성  
생성된 배열에 인수들을 저장하고 메서드에 전달  
인수의 개수는 런타임에 자동 생성된 배열의 길이로 알 수 있음  
호출될 때마다 새로운 배열 할당 및 초기화로 인한 성능 이슈 존재  

````java
    //간단한 가변인수 메서드
    static int sum(int... args) {
        int sum = 0;
        for (int arg : args)
            sum += arg;
        return sum;
    }
  
    //런타임에 정해지는 배열의 크기로 인한 문제점
    static int min(int... args) {
        if (args.length == 0)   //컴파일 오류가 아닌 런타임 오류
            throw new IllegalArgumentException("인수가 한개 이상 필요.");
        ...
    }
````
<br>

## 해결책

````java
  static int min(int firstArg, int... args) {   //인수의 개수가 한개 이상
      ...
  }
````

<br>
