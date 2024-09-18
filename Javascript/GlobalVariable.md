# 전역 변수의 문제점

## 변수의 생명주기
변수의 생명주기는 메모리 공간이 확보된 시점부터 메모리 공간이 해제되어 가용 메모리 풀에 반환되는 시점까지  
지역변수의 생명주기는 함수의 생명주기와 일치(호이스팅도 스코프 단위로 동작)   

````javascript
var x = "global";

function foo() {
  console.log(x);     // undefined
  var x = "local";    // 호이스팅 동작
}

foo();
console.log(x);       // global
````

<br>

전역 코드는 함수 호출 같은 특별한 진입점이 없고 코드가 로드되자마자 곧바로 해석되고 실행  
var 키워드로 선언한 전역 변수는 전역 객체의 프로퍼티로, 전역 객체의 생명주기와 일치  
> 전역 객체는 코드가 실행되기 이전 단계에 자바스크립트 엔진에 의해 가장 먼저 생성되는 특수한 객체  
> 전역 객체는 표준빌트인 객체, 호스트 객체, var 키워드 전역변수, 전역 함수를 프로퍼티로 보유  

<br>

## 문제점
1. 암묵적 결합  
  모든 코드가 전역 변수를 참조하고 변경할 수 있는 암묵적 결합(implicit coupling)을 허용  

2. 긴 생명주기  
  전역 변수의 생명 주기가 길어서 메모리 리소스도 오랜 기간 점유  

3. 스코프 체인 종점에 존재  
  변수 검색시에 가장 마지막에 검색되어 속도가 가장 느림  

4. 네임스페이스 오염  
  자바스크립트는 파일이 분리되어 있어도 하나의 전역 스코프를 공유  
  다른 파일 내에서 동일한 이름으로 명명된 전역 변수나 전역 함수가 같은 스코프 내에 존재하면 예상치 못한 결과 초래  

<br>

## 전역 변수 사용 억제 방법
변수의 스코프는 좁으면 좁을수록 좋음  

1. 즉시 실행 함수  
  모든 코드를 즉시 실행 함수로 감싸서 지역 변수로 선언  
  
    ````javascript
    (function () {
      var foo = 10       // 즉시 실행 함수의 지역 변수
      ...
    }());
  
    console.log(foo);    // ReferenceError: foo is not defined
    ````

<br>

2. 네임스페이스 객체  
  전역에 네임스페이스 담당 객체를 생성  
  전역 변수처럼 사용하고 싶은 변수를 프로퍼티로 계층적 추가  

    ````javascript
    var MYAPP = {};                    // 전역 네임스페이스 객체
  
    MYAPP.person = {
      name: "Lee",
      address: "Seoul"
    };
  
    console.log(MYAPP.person.name);    // Lee
    ````

<br>

3. 모듈 패턴
  클래스를 모방해서 관련이 있는 변수와 함수를 모아 즉시 실행 함수로 감싸 하나의 모듈을 만드는 방식
  자바스크립트의 클로저를 기반으로 동작

    ````javascript
    var Counter = (function () {
      // private
      var num = 0;
  
      // public
      return {
        increase() {
          return ++num;
        },
        decrease() {
          return --num;
        }
      };
    }());
  
    console.log(Counter.num);           // undefined
  
    console.log(Counter.increase());    // 1
    console.log(Counter.increase());    // 2
    console.log(Counter.decrease());    // 1
    console.log(Counter.decrease());    // 0
    ````

<br>

4. ES6 모듈  
  파일 자체의 독자적인 모듈 스코프를 제공
  모듈 내에서 var 키워드로 선언한 변수는 더는 전역 변수와 window 객체의 프로퍼티도 아닌 변수  
  모듈의 파일 확장자는 mjs를 권장  

<br>
