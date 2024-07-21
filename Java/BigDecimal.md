## BigDecimal
자바에서 가장 정밀하게 숫자를 저장하고 표현할 수 있는 자료형  
돈과 정밀한 소수점 계산시(금융 관련) 필수  
보다 정밀한 계산을 위해 int, long 사용도 가능하지만 BigDecimal과는 다르게 소수점을 따로 관리  
double, float과 다르게 내부적으로 십진수로 저장하여 높은 정밀도 보장  

````java
//double, float 사용시 오차
System.out.println(1.03 - 0.42);      //0.6100000000000001
Systme.out.println(1.00 - 9 * 0.10);  //0.09999999999999998
````

<br>

## 구조
1. precision(unscale)  
  숫자를 표현하는 전체 자리수  

2. scale  
  전체 소수점 자리수(32bit 소수점 크기 보유)   

3. DECIMAL128  
  IEEE 754-2008에 의한 표준화  
  부호와 소수점을 포함한 최대 34자리 십진수를 저장하는 형식  

<br>

## 기본상수
흔히 쓰이는 상수는 기본 상수로 초기화 가능  
    * BigDecimal.ZERO  
    * BigDecimal.ONE  
    * BigDecimal.TEN  

<br>

## 초기화 방식
문자열을 이용한 초기화 방식이 가장 안전  

````java
//안전하지 않은 방식
new BigDecimal(0.01);

//안전한 방식
new BigDecimal("0.01");
BigDecimal.valueOf(0.01); //double.toString()을 이용하여 위와 동일한 결과
````
<br>

## 사칙연산
double, float 보다 복잡하고 번거로움  
    
1. 더하기  
````java
a.add(b);  
````

2. 빼기  
````java
a.substract(b);  
````

4. 곱하기  
````java
a.multiply(b);  
````

4. 나누기  
````java
a.divide(b);
a.divide(b, 3, RoundingMode.HALF_EVEN);   //반올림
a.remainder(b, MathContext.DECIMAL128);   //전체 자리수 34자리 제한
````

5. 절대값
````java
new BigDecimal("-3").abs();
````

<br>

## 소수점  
1. 소수점 이하 절사
````java
new BigDecimal("1.1234567890").setScale(0, RoundingMode.FLOOR);
new BigDecimal("1.1234567890").setScale(0, RoundingMode.CEILING); //절사 후 1 증가
````

2. 소수점 trim
````java
new BigDecimal("0.1234567890").stripTrailingZeros();
````

<br>

