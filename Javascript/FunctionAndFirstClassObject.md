# 함수와 일급 객체  

## 일급 객체  
1. 무명의 리터럴로 생성 가능(런타임에 생성 가능)

2. 변수나 자료구조에 저장 가능

3. 함수의 매개변수에 전달 가능

4. 함수의 반홥값으로 사용 가능

<br>

함수가 일급 객체라는 것은 함수를 객체와 동일하게 사용 가능  
객체는 값이므로 함수는 값과 동일하게 사용 가능  
함수는 객체이지만 호출 가능  

<br>

## 함수 객체 프로퍼티  
함수 객체의 데이터 프로퍼티는 `arguments`, `caller`, `length`, `name`, `prototype`  

<br>

````javascript
function square(number) {
  return number * number;
}

console.log(Object.getOwnPropertyDescriptors(square));
/*
{
  length: {value: 1, writable: false, enumerable: false, configurable: true},
  name: {value: "square", writable: false, enumerable: false, configurable: true},
  arguments: {value: null, writable: false, enumerable: false, configurable: false},
  caller: {value: null, writable: false, enumerable: false, configurable: false},
  prototype: {value: {...}, writable: true, enumerable: false, configurable: false}
}
*/

// __proto__는 square 함수의 프로퍼티가 아니다.
console.log(Object.getOwnPropertyDescriptor(square, '__proto__'));    // undefined

// __proto__는 Object.prototype 객체의 접근자 프로퍼티다.
// square 함수는 Object.prototype 객체로부터 __proto__ 접근자 프로퍼티를 상속받는다.
console.log(Object.getOwnPropertyDescriptor(Object.prototype, '__proto__'));
// {get: f, set: f, enumerable: false, configurable: true}
````

<br>

### arguments  
함수 객체의 arguments 프로퍼티 값은 arguments 객체  
함수 호출 시 전달된 인수들의 정보를 담고 있는 순회 가능한 유사 배열 객체  
현재 일부 브라우저에서 지원하고 있지만 ES3부터 표준에서 폐지  
자바스크립트 함수는 매개변수와 인수의 개수가 일치하는지 확인하지 않음  

<br>

````javascript
function multiply(x, y) {
  return x * y;
}

console.log(multiply());           // NaN
console.log(multiply(1));          // NaN
console.log(multiply(1, 2));       // 2
console.log(multiply(1, 2, 3));    // 2
````

<br>

함수를 정의할 때 선언한 매개변수는 함수 몸체 내부에서 변수와 동일  
암묵적으로 `undefined` 초기화 후 인수 할당  
초과된 인수는 무시되지만 버리지 않고 암묵적으로 보관  
arguemnts 객체는 가변 인자 함수를 구현할 때 유용  

<br>

````javascript
function sum() {
  let res = 0;

  for (let i = 0; i < arguments.length; i++) {
    res += arguments[i];
  }

  return res;
}

console.log(sum());           // 0
console.log(sum(1, 2));       // 3
console.log(sum(1, 2, 3));    // 6
````

<br>

arguments 객체는 배열이 아닌 `유사 배열 객체`  
length 프로퍼티를 가진 for문 순회 가능 객체  
배열 메서드를 호출할 경우 오류 발생  
따라서 배열 메서드를 사용하기 위해서 간접 호출 필수  
ES6부터 유사 배열 객체이면서 동시에 이터러블  

<br>

````javascript
function sum() {
  const array = Array.prototype.slice.call(arguments);
  return array.reduece(function (pre, cur) {
    return pre + cur;
  }, 0);
}
````

<br>

이런 번거로움 해결을 위해 ES6에서 `Rest` 파라미터 도입  

<br>

````javascript
function sum(...args) {
  return args.reduce((pre, cur) => pre + cur, 0);
}
````

<br>

### caller  
ECMAScript 사양에 포함되지 않은 비표준 프로퍼티  
사용하지 말고 참고로만 사용 권장  

<br>

````javascript
function foo(func) {
  return func();
}

function bar() {
  return 'caller: ' + bar.caller;
}

// 브라우저 실행 결과
console.log(foo(bar));    // caller: function foo(func) {...}
console.log(bar());       // caller: null
````

<br>

### length  
선언한 매개변수의 개수  
arguments 객체의 length 프로퍼티와 값이 다를 수 있음  

<br>

````javascript
function () {}
console.log(foo.length);    // 0

function bar(x, y) {
  return x * y;
}
console.log(bar.length);    // 2
````

<br>

### name  
함수 이름  
ES6 이전까지는 비표준이였지만 이후에는 정식 표준  
ES5와 ES6의 동작 차이 존재  

<br>

````javascript
// 기명 함수 표현식
var namedFunc = function foo() {};
console.log(namedfunc.name);        // foo

// 익명 함수 표현식
var anonymousFunc = function() {};
// ES5: name 프로퍼티는 빈 문자열
// ES6: name 프로퍼티는 함수 객체를 가리키는 변수 이름 값
console.log(anonymousFunc.name);    // anonymousFunc

// 함수 선언문
function bar() {}
console.log(bar.name);              // bar
````

<br>

### \_\_proto\_\_
모든 객체는 [[Prototype]] 내부 슬롯을 보유  
상속을 구현하는 프로토타입 객체를 가리킴  
\_\_proto\_\_ 프로퍼티는 [[Prototype]] 내부 슬롯이 가리키는 포로토타입 객체에 접근하기 위한 접근자 프로퍼티  

<br>

````javascript
const ob = { a: 1 };

// 객체 리터럴 방식으로 생성한 객체 프로토타입 객체는 Object.prototype
console.log(obj.__proto__ === Object.prototype);    // true

// Object.prototype 프로퍼티 상속
// hasOwnProperty 메서드는 Object.prototype 메서드
console.log(obj.hasOwnProperty('a'));               // true
console.log(obj.hasOwnProperty('__proto__'));       // false
````

<br>

### prototype  
생성자 함수로 호출 가능한 함수 객체  
즉 `constructor`만이 소유하는 프로퍼티  
생성할 인스턴스의 프로토타입 객체를 가리킴  

<br>

````javascript
// 함수 객체는 prototype 프로퍼티 소유
(function () {}).hasOwnProperty('property');    // true

// 일반 객체는 prototype 프로퍼티 미소유
({}).hasOwnProperty('prototype');               // false
````

<br>
