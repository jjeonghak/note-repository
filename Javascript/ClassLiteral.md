## 객체 리터럴

### 객체
자바스크립트는 객체 기반의 프로그래밍 언어  
자바스크립트를 구성하는 거의 모든 것(원시 값 제외)이 객체  
원시 값은 불변, 객체 타입 값은 가변  
0개 이상의 프로퍼티와 메서드로 구성되며 키-값 형식  

````javascript
var counter = {
  num: 0,
  increase: function() {
    this.num++;
  }
}
````

<br>

### 객체 리터럴에 의한 객체 생성
객체 리터럴은 중괄호({}) 내에 0개 이상의 프로퍼티와 메서드를 정의  
코드 블록 중괄호({})와 의미/문법이 다름(세미콜론 여부 차이)  

````javascript
var person = {
  name: "Lee",
  sayHello: function() {
    console.log(`Hello! My name is ${this.name}.`);
  }
};

console.log(typeof person);    // object
console.log(person);           // {name: "Lee", sayHello: f}
````

<br>

### 프로퍼티
객체를 구성하는 원소이며, 키-값 형식  
식별자 네이밍 규칙을 따르지 않으면 키값에 반드시 따옴표 사용  

````javascript
var person = {
  firstName: "Ung-mo",    // 식별자 네이밍 규칙 준수
  "middle-name": "",      // 식별자 네이밍 규칙 미준수, 따옴표사용
  last-name: "Lee"        // 식별자 네이밍 규칙 미준수, SyntaxError: Unexpected token -
};
````

<br>

동적으로 프로퍼티 키 생성 가능  
빈 문자열로 프로퍼티 키 생성이 가능하지만 권장하지 않음  
문자열 또는 심벌 값을 사용하지 않으면 암묵적 타입 변환을 통해 문자열로 변환  

````javascript
var obj = {};
var key = "hello";
obj[key] = "world";

console.log(obj);    // {hello: "world"}
````

<br>

중복된 키값을 사용하는 경우 먼저 나중 선언된 프로퍼티 덮어쓰기

````javascript
var foo = {
  name: "Lee",
  name: "Kim"
};

console.log(foo);    // {name: "Kim"}
````

<br>

### 메서드
함수는 일급 객체  
함수는 값으로 취급 가능하기 때문에 프로퍼티 값으로 사용 가능  

````javascript
var circle = {
  radius: 5,
  getDiameter: function() {
    return 2 * this.radius;
  }
};
````

<br>

### 프로퍼티 접근
마침표 표기법: 마침표 프로퍼티 연산자(.)를 사용  
대괄호 표기법: 대괄호 프로퍼티 연산자([...]) 사용, 단 키는 따옴표로 감싼 문자열  
객체에 존재하지 않는 프로퍼티에 접근하는 경우 undefined 반환  

````javascript
var person = {
  name: "Lee"
};

console.log(person.name);       // Lee
console.log(person['name']);    // Lee
console.log(person[name]);      // ReferenceError: name is not defined

console.log(person.age);        //undefined
````

<br>

### 프로퍼티 동적 생성
선언에서 존재하지 않은 값을 할당하면 프로퍼티가 동적으로 생성  

````javascript
var person = {
  name: "Lee"
};

person.age = 20;
console.log(person);    // {name: "Lee", age: 20}
````

<br>

### 프로퍼티 삭제
`delete` 연산자를 사용  
존재하지 않는 프로퍼티인 경우 아무런 에러 없이 무시  

````javascript
var person = {
  name: "Lee",
  age: 20
};

delete person.age;        // age 프로퍼티 삭제
delete person.address;    // 에러 없이 무시
````

<br>

### 프로퍼티 축약
프로퍼티 값을 변수(식별자)로 대체가능  
변수 이름과 프로퍼티 키가 동일한 경우 생략가능  

````javascript
var x = 1, y = 2;

var obj1 = {
  x: x,
  y: y
};

var obj2 = { x, y };

console.log(obj1);    // {x: 1, y: 2}
console.log(obj2);    // {x: 1, y: 2}
````

<br>

### 계산된 프로퍼티 이름
문자열로 평가되는 표현식을 프로퍼티 키로 사용가능  
이를 위해 대괄호 표기법 사용 필수  

````javascript
var prefix = "prop";
var i = 0;

var obj = {
  [`$[prefix]-$[++i]`] : i,
  [`$[prefix]-$[++i]`] : i
};

obj[`$[prefix]-$[++i]`] = i;

console.log(obj);               // {prop-1: 1, prop-2: 2, prop-3: 3}
````

<br>

#### 메서드 축약 표현
ES6에서 메서드 정의할 때 `function` 키워드를 생략가능  

````javascript
var obj = {
  name: "Lee",
  sayHi() {
    console.log("Hi " + this.name);
  }
}
````

<br>
