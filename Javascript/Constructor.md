# 생성자 함수에 의한 객체 생성

## Object 생성자 함수
`new` 연산자와 함께 Object 생성자 함수 호출시 빈 객체 반환  
생성자 함수란 `new` 연산자와 함께 호출하여 객체 인스턴스를 생성하는 함수  
Object 이외에도 String, Number, Boolean, Function, Array, Date, RegExp, Promise 등 빌트인 생성자 함수 존재  

````javascript
// 빈 객체 생성
const person = new Object();

// 프로퍼티 동적 추가
person.name = 'Lee';
person.sayHello = function () {
  console.log(`hi ${this.name}`);
}

console.log(person);    // {name: "Lee", sayHello: f}
person.sayHello();      // hi Lee
````

<br>

## 생성자 함수

### 객체 리터럴에 의한 객체 생성 방식의 문제  
객체 리터럴에 의한 객체 생성 방식은 단 하나의 객체만 생성  
객체는 프로퍼티를 통해 객체 고유 `상태`를 표현  
메서드를 통해 상태 데이터인 프로퍼티를 참조하고 조작하는 `동작` 표현  
그렇기 때문에 객체 리터럴 방식은 프로퍼티 구조가 동일해도 매번 같은 프로퍼티와 메서드를 기술 필수  

````javascript
const circle1 = {
  radius: 5,
  getDiameter() {
    return 2 * this.radius;
  }
};

const = circle2 = {
  radius: 10,
  getDiameter() {
    return 2 * this.radius;
  }
};
````

<br>

### 생성자 함수에 의한 객체 생성 방식의 장점  
템플릿처럼 생성자 함수를 사용해서 프로퍼티 구조가 동일한 객체를 편하게 여러개 생성 가능  
샹성자 함수는 자바와 다르게 형식이 정해져 있는 것이 아닌 일반 함수와 동일한 방법으로 정의  
대신 `new` 연산자와 함께 호출하면 생성자 함수로 동작  

````javascript
function Circle(radius) {
  this.radius = radius;
  this.getDiameter = function () {
    return 2 * this.radius;
  };
}

const circle1 = new Circle(5);
const circle2 = new Circle(10);

// new 연산자 없이 호출시 생성자 함수로 동작하지 않음
// 일반 함수로 호출될 경우 this는 전역 객체를 가리킴
const circle3 = Circle(15);    // undefined
console.log(radius);           // 15
````

<br>

#### this  
this는 객체 자신의 프로퍼티나 메서드를 참조하기 위한 `자기 참조 변수`(self-referencing variable)  
this 바인딩은 함수 호출 방식에 의해 동적으로 결정  

| **함수 호출 방식** | **this value** |
|--|--|
| 일반 함수 호출 | 전역 객체 |
| 메서드 호출 | 메서드를 호출한 객체 |
| 생성자 함수 호출 | 생성자 함수가 생성할 인스턴스 |

````javascript
function foo() {
  console.log(this);
}

// 일반적 함수 호출
// 브라우저 환경은 window, Node.js 환경은 global
foo();                     // global

// 메서드 호출
const obj = { foo };
obj.foo();                 // obj

// 생성자 함수 호출
const inst = new foo();    // inst
````

<br>

### 생성자 함수의 인스턴스 생성 과정  
생성자 함수는 인스턴스 생성과 생성된 인스턴스 초기화를 담당  

1. 인스턴스 생성과 this 바인딩  
암묵적으로 빈 객체가 생성 및 this 바인딩  
이 처리는 함수 몸체의 코드가 한 줄씩 실행되는 런타임 이전에 실행  

2. 인스턴스 초기화  
this에 바인딩되어 있는 인스턴스를 초기화  
이 처리는 개발자가 기술  

3. 인스턴스 반환  
생성자 함수 내부에 모든 처리가 완료되면 바인딩된 this가 암묵적으로 반환  
return this 없이 객체가 반환되는 이유  
이때 명시적으로 객체 return문 작성시 암묵적 this 반환이 무시  
하지만 원시값을 반환하면 return문이 무시되고 암묵적 this 반환  
그렇기 때문에 생성자 함수 내부에는 return문 생략 필수  

<br>

### 내부 메서드 [[Call]]과 [[Construct]]
함수는 객체이므로 일반 객체와 동일하게 동작 가능  
일반 객체가 가지고 있는 내부 슬롯과 내부 메서드를 모두 보유  

````javascript
function foo() {}

// 함수는 객체이므로 프로퍼티 및 메서드 소유 가능
foo.prop = 10;

foo.method = function () {
  console.log(this.prop);
};

foo.method();    // 10
````

<br>

일반 객체는 호출할 수 없지만 함수 객체는 호출 가능  
함수 객체만을 위한 [[Environment]], [[FormalParameters]] 등의 내부 슬롯 보유  
함수 객체만을 위한 [[Call]], [[Construct]] 내부 메서드 보유  
일반 호출시 [[Call]], `new` 연산자와 함께 호출시 [[Construct]] 호출  

내부 메서드 [[Call]]을 갖는 함수 객체를 `callable`  
내부 메서드 [[Construct]]를 갖는 함수 객체를 `constructor`, 아닌 함수 객체를 `non-constructor`  
모든 함수 객체는 `callable`이지만 꼭 `constructor`인 것은 아님  

````javascript
function foo() {}

// [[Call]] 호출
foo();

// [[Construct]] 호출
new foo();
````

<br>

### constructor와 non-constructor 구분  
자바스크립트 엔진은 함수 정의를 평가하여 함수 객체를 생성할 때 구분  
ECMAScript 사양에서 메서드로 인정하는 범위가 일반적인 의미의 메서드보다 좁음  

````javascript
// 일반 함수 정의
function foo() {}
const bar = function () {};

// 프로퍼티 x의 값으로 할당된 것은 일반 함수로 정의
// 이는 메서드로 인정하지 않음
const baz = function () {
  x: function () {}
};

// 일반 함수로 정의된 함수만 constructor
new foo();        // -> foo {}
new bar();        // -> bar {}
new baz().x();    // -> x {}

// 화살표 함수 정의
const arrow = () => {}
new arrow();      // TypeError: arrow is not a constructor

// 메서드 정의: ES6의 메서드 축약 표현만 메서드로 인정
const obj = {
  x() {}
};

new obj.x();      // TypeError: obj.x is not a constructor
````

<br>

### new 연산자  
일반 함수와 생성자 함수에 특별한 형식적 차이는 없음  
생성자 함수가 new 연산자 없이 호출되는 것을 방지하기 위해 ES6에서 `new.target` 지원  
함수 내부에 `new.target`을 사용하면 new 연산자와 함께 호출되었는지 확인 가능  
보통 함수 자신을 가리키지만 new 연산자와 호출되지 않은 경우 undefined  

````javascript
function Circle(radius) {
  if (!new.target) {
    return new Circle(radius);
  }
  this.radius = radius;
  this.getDiameter = function () {
    return 2 * radius;
  };
}
````

<br>

### 스코프 세이프 생성자 패턴(scope-safe constructor)  
`new.target`은 ES6에서 도입된 최신 문법으로 IE에서 지원하지 않음  

````javascript
function Circle(radius) {
  // this 바인딩을 통해 생성자 호출 여부 판단
  // new 연산자와 호출되지 않은 경우 this는 global
  if (!(this instanceof Circle)) {
    return new Circle(radius);
  }
  this.radius = radius;
  this.getDiameter = function () {
    return 2 * this.radius;
  };
}
````

<br>

Object, Function 생성자 함수는 new 연산자 없이도 동일하게 동작  
String, Number, Boolean 생성자 함수는 new 연산자 없는 경우 객체가 아닌 원시값 반환  

````javascript
let obj = new Object();
console.log(obj);                 // {}
obj = Object();
console.log(obj);                 // {}

let f = new Function('x', 'return x');
console.log(f);                   // f anonymous(x) { return x }
f = Function('x', 'return x');
console.log(f);                   // f anonymous(x) { return x }

const str = String(123);
const num = Number(123);
const bool = Boolean('true');

console.log(str, typeof str);      // 123 string
console.log(num, typeof num);      // 123 number
console.log(bool, typeof bool);    // true boolean
````

<br>
