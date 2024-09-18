# 함수

## 함수
수학의 함수와 같이 입력을 받아 출력을 내보내는 일련의 과정  
일련의 과정을 문으로 구현하고 코드 블록으로 감싸서 하나의 실행 단위로 정의한 것  

<br>

## 함수 리터럴
함수는 객체 타입의 값  
함수도 함수 리터럴로 생성 가능  

````javascript
var f = function add(x, y) {
  return x + y;
};
````

<br>

## 함수 정의
| 함수 정의 방식 | 예시 |
|-|-|
| 함수 선언문 | function add(x, y) { return x + y; } |
| 함수 표현식 | var add = function add(x, y) { return x + y; }; |
| 생성자 함수 | var add = new Function("x", "y", "return x + y"); |
| 화살표 함수 | var add = (x, y) => x + y; |

<br>

## 함수 선언문
함수 선언문은 리터럴과 형태가 동일하지만 함수 이름을 생략 불가  
문맥에 따라 함수 리터럴을 표현식이 아닌 문인 함수 선언문으로 해석 가능  
자바스크립트 엔진은 함수 선언문을 해석해서 함수 이름과 동일한 식별자를 암묵적으로 생성  
함수는 함수 이름으로 호출하는 것이 아닌 함수 객체를 가리키는 식별자를 통해 호출  

````javascript
// SyntaxError: Function statements require a function name
function(x, y) {
  return x + y;
}

// 함수 선언문으로 해석
function foo() { console.log("foo"); }
foo();                                    // foo

// 함수 리터럴을 피연산자로 사용한 경우 함수 리터럴 표현식으로 해
(function bar() { console.log("bar"); })
bar();                                    // ReferenceError: bar is not defined
````

<br>

## 함수 표현식
함수는 객체 타입의 값(일급 객체)  
함수 이름은 함수 몸체 내부에서만 유효한 식별자이므로 호출 불가  

````javascript
var add = function foo(x, y) {
  return x + y;
}

console.log(add(2, 5));    // 7
console.log(foo(2, 5));    // ReferenceError: foo is not defined
````

<br>

## 함수 생성 시점과 함수 호이스팅
함수 선언문과 함수 표현식은 함수 생성 시점이 상이  
함수 선언문은 암묵적으로 생성된 식별자가 생성되며 함수 객체로 바로 초기화  
var 키워드로 선언된 함수는 undefined로 초기화  

````javascript
console.dir(add);          // f add (x, y)
console.dir(sub);          // undefined

console.log(add(2, 5));    // 7
console.log(sub(2, 5));    // TypeError: sub is not a function

// 함수 선언문
function add(x, y) {
  return x + y;
}

// 함수 표현식
var sub = function(x, y) {
  return x + y;
}
````

<br>

## 생성자 함수
Function 생성자 함수로 함수를 생성하는 방식은 일반적이지 않음  
클로저를 생성하지 않는 등 함수 선언문 또는 함수 표현식과 다른 동작  
	
````javascript
var add1 = (function() {
  var a = 10;
  return function(x, y) {
    return x + y + a;
  };
} ());

var add2 = (function() {
  var a = 10;
  return new Function("x", "y", "return x + y + a;");
} ());

console.log(add1(1, 2));    // 13
console.log(add2(1, 2));    // ReferenceError: a is not defined
````

<br>

## 화살표 함수
ES6에서 도입된 함수 선언 방식  
항상 익명 함수로 정의  
표현뿐만 아니라 내부 동작 간략화  

````javascript
const add = (x, y) => x + y;
console.log(add(2, 5));         // 7
````

<br>

## 함수 호출
함수가 정의된 파라미터 갯수보다 많은 갯수를 넘긴 경우 무시  
하지만 삭제되는 것이 아닌 저장  

````javascript
function add(x, y) {
  console.log(arguments);    // Arguments(3) [2, 5, 10, callee: f, Symbol(Symbol.iterator): f]
  return x + y;
}

add(2, 5, 10);
````

<br>

## 인수 확인
파라미터 검증 또는 단축평가를 통해서 부적절한 호출 사전 방지 가능  
ES6에서 도입된 매개변수 기본값 사용  

````javascript
function add(a = 0, b = 0, c = 0) {
  return a + b + c;
}
````

<br>

## 반환문
return 키워드와 표현식(반환값)으로 이루어진 문  
반환문은 return 키워드 뒤에 오는 표현식을 평가해서 반환  
명시적으로 지정하지 않는 경우 undefined 반환  
반환문은 함수 몸체 내부에서만 사용 가능  

````javascript
function multiply(x, y) {
  return x * y;                       // 반환문
  console.log("ignore statement");    // 반환문 이후에 다른 문이 존재하면 실행되지 않고 무시
}

function add(x, y) {
  return                              // 세미콜론 자동 삽입 기능(ASI)에 의해 세미콜론 추가
  x + y;                              // 무시
}
````

<br>

## 매개변수 전달 방식
매개변수 또한 타입에 따라 값/참조에 의한 전달 방식을 그대로 적용  
객체를 매개변수로 사용한 경우 부수 효과 발생  

````javascript
function changeVal(primitive, obj) {
  primitive += 100;
  obj.name = "Kim";
}

// 외부 상태
var num = 100;
var person = { name: "Lee" };

changeVal(num, person);

// 원시 값은 원본이 훼손되지 않고, 객체는 원본이 훼손
console.log(num);      // 100
console.log(person)    // {name: "Kim"}
````

<br>

## 즉시 실행 함수
함수 정의와 동시에 즉시 호출되는 함수(IIFE, Immediately Invoked Function Expression)  
단 한번만 호출되며 다시 호출 불가  
익명 함수 또는 그룹 연산자 (...) 내의 기명 함수 형식  

````javascript
// 익명 즉시 실행 함수
(function () {
  return 3 * 5;
}());

// 기명 즉시 실행 함수
(function foo() {
  return 3 * 5;
}());

foo();    // ReferenceError: foo is not defined
````

<br>

````javascript
var res = (function () {
  return 3 * 5;
}());

res = (function (a, b) {
  return a * b;
}(3, 5));
````

<br>

## 중첩 함수
함수 내부에 정의된 함수는 중첨 함수(nested function) 또는 내부 함수(inner function)  
중첩 함수를 포한하는 함수는 외부 함수(outer function)  
일반적으로 중첩 함수는 자신을 포함하는 외부 함수를 돕는 헬퍼 함수(helper function)의 역할  
단 if, for 문 등의 코드 블록에서 함수 선언문을 정의하는 것은 호이스팅 혼란 발생으로 권장하지 않음  

````javascript
function outer() {
  var x = 1;

  function inner() {
    var y = 2;
    console.log(x + y);    // 3
  }

  inner();
}

outer();
````

<br>

## 콜백 함수
함수의 매개변수를 통해 다른 함수의 내부로 전달되는 함수  
매개변수를 통해 함수의 외부에서 콜백 함수를 전달받은 함수는 고차 함수(higher-order function)  
고차 함수는 콜백 함수를 자신의 일부분으로 합성  
콜백 함수는 함수형 프로그래밍 패러다임, 비동기 처리, 배열 고차 함수 등 사용  

````javascript
var arrMap = [1, 2, 3].map(function (item) {
  return item * 2;
});

var arrFilter = [1, 2, 3].filter(function (item) {
  return item % 2;
});

var arrReduce = [1, 2, 3].reduce(function (acc, cur) {
  return acc + cur;
});
````

<br>

## 순수 함수와 비순수 함수
순수함수(pure function)는 부수 효과가 발생하지 않는 함수  
비순수함수(impure function)은 부수 효과가 발생하는 함수  
순수함수는 동일한 인수에는 언제나 동일한 값을 반환, 즉 외부 상태에 의존하지 않는 함수  
만약 함수의 내부 상태에만 의존한다해도 호출할때마다 변경되는 값(시간 등)을 의존하는 경우 비순수함수  

````javascript
var count = 0;

// 순수 함수
function pureIncrease(n) {
  return ++n;
}

// 비순수 함수
function impureIncrease() {
  return ++count;
}
````

<br>
