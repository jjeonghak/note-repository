# 프로토타입  

자바스크립트는 멀티 패러다임 프로그래밍 언어  
명령형(`imperative`), 함수형(`functional`), 프로토타입 기반(`prototype-based`), 객체지향 프로그래밍(`object-oriented`) 지원   
원시값을 제외한 자바스크립트를 이루고 있는 거의 모든 것이 객체  

<br>

## 객체지향 프로그래밍  
명령어 또는 함수의 목록을 보는 전통적인 명령형 프로그래밍의 절차지향적 관점과는 다름  
여러 개의 독립적 단위(객체)의 집합  
속성을 통해 여러 개의 값을 하나의 단위로 구성한 복합적 자료구조  

객체는 상태(`state`)를 나타내는 데이터와 상태 데이터를 조작할 수 있는 동작(`behavior`) 보유  
상태 데이터와 동작을 하나의 논리적인 단위로 묶은 복합적인 자료구조  

<br>

## 상속과 프로토타입  
상속은 어떤 객체의 프로퍼티 또는 메서드를 다른 객체가 그대로 사용 가능  
자바스크립트는 프로토타입을 기반으로 상속을 구현  

<br>

````javascript
function Circle(radius) {
  this.radius = radius;
}

Circle.prototype.getArea = function () {
  return Math.PI * this.radius ** 2;
};

const circle1 = new Circle(1);
const circle2 = new Circle(2);

// 부모 객체의 역할을 하는 프로토파입으로부터 getArea 메서드 공유
console.log(circle1.getArea === circle2.getArea);    // true

console.log(circle1.getArea());                      // 3.141592653589793
console.log(circle2.getArea());                      // 12.566370614359172
````

<br>

## 프로토타입 객체  
프로토타입 객체는 객체 간 상속을 구현하기 위해 사용  
[[Prototype]] 내부 슬롯에 접근하기 위해서 `__proto__` 접근자 사용  

<br>

### \_\_proto\_\_  
모든 객체는 `__proto__` 접근자 프로퍼티를 통해 자신의 프로토타입에 간접접근 가능  
getter/setter 함수([[Get]], [[Set]] 어트리뷰트에 할당된 함수)를 통해 프로토타입 취득 또는 할당  

<br>

````javascript
const obj = {};
const parent = { x: 1 };

// getter 함수인 get __proto__ 메서드를 통해 obj 객체의 프로토타입 취득
obj.__proto__;

// setter 함수인 set __proto__ 메서드를 통해 obj 객체의 프로토타입 교체
obj.__proto__ = parent;

console.log(obj.x);    // 1
````

<br>

해당 접근자 프로퍼티는 객체가 보유하지 않고 Object.prototype의 프로퍼티  

<br>

````javascript
const person = { name: 'Lee' };

console.log(person.hasOwnProperty('__proto__'));     // false

console.log(Object.getOwnPropertydescriptor(Object.prototype, '__proto__'));
// {get: f, set: f, enumerable:false, confiturable: true}

console.log({}.__proto__ === Object.prototype);      // true
````

<br>

[[Prototype]] 내부 슬롯의 값, 즉 프로토타입에 접근을 위한 프로퍼티가 존재하는 이유는 상호 참조에 의한 프로토타입 체인 생성 방지를 위해  
프로토타입 체인은 단방향 링크드 리스트로 구현 필수  
확인 없이 프로토타입 교체를 방지하기 위해 `__proto__` 접근자 프로퍼티 사용  

<br>

````javascript
const parent = {};
consst child = {};

child.__proto__ = parent;
parent.__proto__ = child;    // TypeError: Cyclic __proto__ value
````

<br>

코드 내에서 `__proto__` 접근자 프로퍼티를 직접 사용하는 것은 권장하지 않음  
직접 상속을 통해 Object.prototype을 상속받지 않은 객체 생성 가능  

<br>

````javascript
const obj = {};
const parent = { x: 1 };

// obj 객체의 프로토타입 취득
Object.getPrototypeOf(obj);

// obj 객체의 프로토타입 교체
Object.setPrototypeOf(obj, parent);

console.log(obj.x);    // 1
````

<br>

### 함수 객체의 prototype 프로퍼티  
함수 객체만이 소유하는 prototype 프로퍼티는 생성자 함수가 생성할 인스턴스 프로토타입  

<br>

````javascript
// 함수 객체는 prototype 프로퍼티를 소유
(function () {}).hasOwnProperty('prototype');    // true

({}).hasOwnProperty('prototype');                // false
````

<br>

생성자 함수가 아닌 `non-constructor` 함수는 prototype 프로퍼티를 소유하지 않음  

<br>

````javascript
// 화살표 함수
const Person = name => {
  this.name = name;
}

// ES6 메서드 축략 표현
const obj = {
  foo() {}
};

// non-constructor
console.log(Person.hasOwnProperty('prototype'));     // false
console.log(Person.prototype);                       // undefined
console.log(obj.foo.hasOwnProperty('prototype'));    // false
console.log(obj.foo.prototype);                      // undefined
````

<br>

| **구분** | **소유** | **값** | **사용 주체** | **사용 목적** |
| -- | -- | -- | -- | -- |
| \_\_proto\_\_ | 모든 객체 | 프로토타입 참조 | 모든 객체 | 객체가 자신의 프로토타입에 접근 또는 교체를 위해 |
| prototype | constructor | 프로토타입 참조 | 생성자 함수 | 생성자 함수가 생성할 객체의 프로토타입 할당을 위해 |

<br>

````javascript
function Person(name) {
  this.name = name;
}

const me = new Person('Lee');

console.log(Person.prototype === me.__proto__);    // true
````

<br>

### 프로토타입의 constructor 프로퍼티와 생성자 함수  
모든 프로토타입은 `constructor` 프로퍼티를 소유  
해당 프로퍼티는 prototype 프로퍼티로 자신을 참조하는 생성자 함수를 가리킴  

<br>

````javascript
function Person(name) {
  this.name = name;
}

const me = new Person('Lee');

console.log(me.constructor === Person);    // true
````

<br>

## 리터럴 표기법에 의해 생성된 객체의 생성자 함수와 프로토타입  
명시적으로 `new` 연산자와 함께 생성자 함수를 호출하지않는 객체 생성 방식  
프로토타입과 생성자 함수는 단독으로 존재할 수 없고 언제나 쌍으로 존재  

<br>

````javascript
const obj = {};

console.log(obj.constructor === Object);    // true
````

<br>

객체 리터럴로 생성한 객체는 Object 생성자 함수와 constructor 프로퍼티로 연결  
Object 생성자 함수에 인수를 전달하지 않으면 내부적으로 추상 연산 `OrdinaryObjectCreate` 호출  
Object.prototype을 프로토타입으로 갖는 빈 객체 생성  

<br>

````javascript
// 인수가 전달되지 않은 경우 추상 연산 OrdinaryObjectCreate 호출
let obj = new Object();

// 인스턴스 -> Foo.prototype -> Object.prototype 순으로 프로토타입 체인 생성
class Foo extends Obejct {}
new Foo();

// Number 객체 생성
obj = new Object(123);

// String 객체 생성
obj = new Object('123');
````

<br>

| **리터럴 표기법** | **생성자 함수** | **프로토타입** |
| -- | -- | -- |
| 객체 리터럴 | Object | Object.prototype |
| 함수 리터럴 | Function | Function.prototype |
| 배열 리터럴 | Array | Array.prototype |
| 정규 표현식 리터럴 | RegExp | RegExp.prototype |

<br>

## 프로토타입의 생성 시점  
리터럴 표기법에 의해 생성된 객체도 생성자 함수와 연결  
프로토타입은 생성자 함수가 생성되는 시점에 생성  
생성자 함수는 사용자 정의 생성자 함수와 기본 빌트인 생성자 함수로 구분 가능  

<br>

### 사용자 정의 생성자 함수와 프로토타입 생성 시점  
함수 정의가 평가되어 함수 객체를 생성하는 시점에 프로토타입도 생성  
생성된 프로토타입의 프로토타입은 언제나 Object.prototype  

<br>

````javascript
console.log(Person.prototype);    // {constructor: f}

function Person(name) {
  this.name = name;
}
````

<br>

### 빌트인 생성자 함수와 프로토타입 생성 시점  
일반 함수와 마찬가리조 빌트인 생성자 함수가 생성되는 시점에 프로토타입 생성  
모든 빌트인 생성자 함수는 전역 객체가 생성되는 시점에 생성  

<br>

## 객체 생성 방식과 프로토타입의 결정  
다양한 방식으로 객체 생성을 해도 `OrdinaryObjectCreate`에 의해 생성  
`OrdinaryObjectCreate`는 필수적으로 자신이 생성할 객체의 프로토타입을 인수로 전달 받음  
빈 객체를 생성 후 객체에 추가할 프로퍼티 목록이 있는 경우 객체에 추가  
이후 인수로 전달받은 프로토타입을 자신이 생성한 객체의 [[Prototype]] 내부 슬롯에 할당  

<br>

### 객체 리터럴에 의해 생성된 객체의 프로토타입  
객체 리터럴에 의해 객체를 생성해도 `OrdinaryObjectCreate` 호출  
객체 리터럴에 의해 생성된 객체의 프로토타입은 Object.prototype  

<br>

````javascript
const obj = { x: 1 };

// 객체 리터럴에 의해 생성된 obj 객체는 Object.prototype 상속
console.log(obj.contructor === Object);    // true
console.log(obj.hasOwnProperty('x'));      // true
````

<br>

### Object 생성자 함수에 의해 생성된 객체의 프로토타입  
Object 생성자 함수를 호출해도 `OrdinaryObjectCreate` 호출  
이때 전달되는 인수는 Object.prototype  
객체 리터럴 방식과는 객체의 프로퍼티 추가 방식이 상이  

<br>

````javascript
const obj = new Object();
obj.x = 1;

// 객체 리터럴에 의해 생성된 obj 객체는 Object.prototype 상속
console.log(obj.contructor === Object);    // true
console.log(obj.hasOwnProperty('x'));      // true
````

<br>

### 생성자 함수에 의해 생성된 객체의 프로토타입  
`new` 연산자와 생성자 함수를 호출해도 `OrdinaryObjectCreate` 호출  
이때 전달되는 인수는 생성자 함수의 prototype  
프로토타입도 객체이기 때문에 프로퍼티 추가/삭제 가능  

<br>

````javascript
function Person(name) {
  this.name = name;
}

Person.prototype.sayHello = function () {
  console.log(`hi, my name is ${this.name}`);
};
````

<br>

## 프로토타입 체인  
모든 프로토타입 객체는 Object.prototype 상속(체인의 종점)  
자바스크립트는 객체의 프로퍼티에 접근하려고 할 때 프로퍼티가 없는 경우 [[Prototype]] 내부 슬롯을 참조해 부모 탐색  
Object.prototype의 프로토타입 [[Prototype]] 내부 슬롯의 값은 `null`  
프로토타입 체인은 자바스크립트의 상속 메커니즘  

<br>

## 오버라이딩과 프로퍼티 섀도잉  
상속 관계에 의해 프로퍼티가 가려지는 현상을 프로퍼티 섀도잉(`property shadowing`)  
호출/삭제시에도 인스턴스 메서드가 호출/삭제  
하위 객체를 통해 프로토타입의 프로퍼티를 변경/삭제는 불가능  
만약 프로토타입 프로퍼티를 변경/삭제하려면 하위 객체를 통해 접근하는 것이 아닌 직접 접근 필요  

<br>

````javascript
const Person = (function () {
  function Person(name) {
    this.name = name;
  }

  Person.prototype.sayHello = function () {
    conosole.log(`hi, my name is ${this.name}`);
  };

  return Person;
}());

const me = new Person('Lee');

// 인스턴스 메서드
me.sayHello = function () {
  console.log('hey, my name is ${this.name});
};

// 프로토타입 메서드는 인스턴스 메서드에 의해 가려짐
me.sayHello();    // hey, my name is Lee
````

<br>

## 프로토타입의 교체  
프로토타입은 임의의 다른 객체로 변경 가능  
생성자 함수 또는 인스턴스에 의해 교체 가능  

<br>

### 생성자 함수에 의한 프로토타입의 교체  
````javascript
const Person = (function () {
  function Person(name) {
    this.name = name;
  }

  // 생성자 함수의 prototype 프로퍼티를 통해 프로토타입 교체
  Person.prototype = {
    // constructor 프로퍼티와 생성자 함수 간의 연결 설정
    // constructor: Person,
    sayHello() {
      console.log(`hi, my name is ${this.name}`);
    }
  };

  return Person;
}());

const me = new Person('Lee');

// 프로토타입을 교체하면 constructor 프로퍼티와 생성자 함수 간의 연결 파괴
console.log(me.constructor === Person);    // false
console.log(me.constructor === Object);    // true
````

<br>

### 인스턴스에 의한 프로토타입의 교체  
인스턴스의 `__proto__` 접근자 프로퍼티(또는 Object.setPrototypeOf 메서드)를 통해 프로토타입 교체 가능  
생성자 함수에 의한 프로토타입 교체 방식은 임의의 객체를 바인딩해서 미래에 생성할 인스턴스의 프로토타입을 교체하는 방식  
인스턴스에 의한 프로토타입 교체 방식은 이미 생성된 객체의 프로토타입을 교체  

<br>

````javascript
function Person(name) {
  this.name = name;
}

const me = new Person('Lee');

const parent = {
  // constructor 프로퍼티와 생성자 함수 간의 연결 설정
  constructor: Person,
  sayHello() {
    console.log(`hi, my name is ${this.name}`);
  }
};

// me 객체 인스턴스의 프로토타입 교체
Object.setPrototypeOf(me, parent);

console.log(me.constructor === Person);                         // true
console.log(me.constructor === Object);                         // false

// 생성자 함수의 prototype 프로퍼티가 교체된 프로토타입 가리킴
console.log(Person.prototype === Object.getPrototypeOf(me));    // true
````

<br>

## instanceof 연산자  
`instanceof` 연산자는 이항 연산자로서 좌변에 객체를 가리키는 식별자, 우변에 생성자 함수를 가리키는 식별자를 피연산자로 받음  
우변의 생성자 함수의 prototype에 바인딩된 객체가 좌변의 객체의 프로토타입 체인 상에 존재하면 true  

<br>

````javascript
function Person(name) {
  this.name = name;
}

const me = new Person('Lee');

console.log(me instanceof Person);             // true
console.log(me instanceof Object);             // true

const parent = {};

// 프로토타입 교체
Object.setPrototypeOf(me, parent);

// Person 생성자 함수와 parent 객체는 연결되어 있지 않음
console.log(Person.prototype === parent);      // false
console.log(parent.constructor === Person);    // false
````

<br>

## 직접 상속  
### Object.create에 의한 직접 상속  
Object.create 메서드는 명시적으로 프로토타입을 지정하여 새로운 객체 생성  
다른 객체 생성 방식과 마찬가지로 추상 연산 `OrdinaryObjectCreate` 호출  
첫 번째 매개변수에는 생성할 객체의 프로토타입으로 지정할 객체  
두 번째 매개변수에는 생성할 객체의 프로퍼티 키와 프로퍼티 디스크립터 객체로 이뤄진 객체  

````javascript
/**
 * 지정된 프로토타입 및 프로퍼티를 갖는 새로운 객체를 생성하여 반환한다.
 * @param {Object} prototype - 생성할 객체의 프로토타입으로 지정할 객체
 * @param {Object} [propertiesObject] - 생성할 객체의 프로퍼티를 갖는 객체
 * @returns {Object} 지정된 프로토타입 및 프로퍼티를 갖는 새로운 객체
 */
Object.create(prototype[, propertiesObject])

// obj -> null
let obj = Object.create(null);
console.log(Object.getPrototypeOf(obj) === null);                // true

// obj = {};와 동일
// obj -> Object.prototype -> null
obj = Object.create(Object.prototype);
console.log(Object.getPrototypeOf(obj) === Object.prototype);    // true

// obj = { x: 1 };와 동일
// obj -> Object.prototype -> null
obj = Object.create(Object.prototype, {
  x: { value:1, writable: true, enumerable: true, configurable: true }
});
console.log(Object.getPrototypeOf(obj) === Object.prototype);    // true

// 임의의 객체를 직접 상속
// obj -> proto -> Object.prototype -> null
const proto = { x: 10 };
obj = Object.create(proto);
console.log(Object.getPrototypeOf(obj) === proto);               // true

// 생성자 함수
// obj = new Person('Lee');와 동일
// obj -> person.prototype -> Object.prototype -> null
function Person(name) {
  this.name = name;
}
obj = Object.create(Person.prototype);
obj.name = 'Lee';
console.log(Object.getPrototypeOf(obj) === Person.prototype);    // true
````

<br>

ESLint에서는 Object.prototype의 빌트인 메서드를 객체가 직접 호출하는 것을 권장하지 않음  
Object.create 메서드를 통해 프로토타입 체인의 종점에 위치하는 객체를 생성 가능하기 때문에  

<br>

````javascript
const obj = Object.create(null);
obj.a = 1;

console.log(Object.getPrototypeOf(obj) === null);               // true

// TypeError: obj.hasOwnProperty is not a function
// console.log(obj.hasOwnProperty('a'));   

// Object.prototype 빌트인 메서드는 객체로 직접 호출하지 않는다
console.log(Object.prototype.hasOwnProperty.call(obj, 'a'));    // true
````

<br>

### 객체 리터럴 내부에서 \_\_proto\_\_에 의한 직접 상속  
두 번째 인자로 프로퍼티를 정의하는 것은 번거로움  
ES6에서는 객체 리터럴 내부에서 `__proto__` 접근자 프로퍼티를 사용해서 직접 상속을 구현 가능  

<br>

````javascript
const proto = { x: 10 };

const obj = {
  y: 20,
  // 객체를 직접 상속
  // obj -> proto -> Object.prototype -> null
  __proto__: proto
};

/* 위 코드는 아래와 동일
const obj = Object.create(proto, {
  y: { value: 20, writable: true, enumerable: true, configurable: true }
});
*/

console.log(obj.x, obj.y);                            // 10 20
console.log(Object.getPrototypeOf(obj) === proto);    // true
````

<br>

## 정적 프로퍼티/메서드  
정적 프로퍼티/메서드는 생성자 함수로 인스턴스를 생성하지 않아도 참조/호출 가능한 프로퍼티/메서드  
해당 정적 프로퍼티/메서드는 프로토타입이 아닌 생성자 함수가 소유  
따라서 인스턴스를 통해 프로토타입에 접근해도 정적 프로퍼티/메서드에는 접근 불가능  

<br>

````javascript
function Person(name) {
  this.name = name;
}

Person.prototype.sayHello = function () {
  console.log(`hi, my name is ${this.name}`);
}

// 정적 프로퍼티
Person.staticProp = 'static prop';

// 정적 메서드
Person.staticMethod = function () {
  console.log('staticMethod');
}

const me = new Person('Lee');

Person.staticMethod();    // staticMethod
me.staticMethod();        // TypeError: me.staticMethod is not a function
````

<br>

## 프로퍼티 존재 확인  
### in 연산자  
`in` 연산자는 객체 내에 특정 프로퍼티가 존재하는지 여부를 반환  
ES6에서 도입된 `Reflect.has` 메서드를 사용해도 동일하게 동작  

<br>

````javascript
/**
 * key: 프로퍼티 키를 나타내는 문자열
 * object: 객체로 평가되는 표현식
 */
key in object

const person = {
  name: 'Lee'
};

console.log('name' in person);                     // true
console.log('address' in person);                  // false

// 상속 받은 모든 프로퍼티 확인
console.log('toString' in person);                 // true

// Reflect.has 메서드도 동일한 동작
console.log(Reflect.has(person, 'name'));          // true
console.log(Reflect.has(person, 'toString'));      // true

// Object.prototype.hasOwnProperty 메서드도 동일한 동작
console.log(person.hasOwnProperty('name'));        // true
console.log(person.hasOwnProperty('toString'));    // true
````

<br>

## 프로퍼티 열거  
### for ... in 문  
객체의 모든 프로퍼티 순회  

<br>

````javascript
const person = {
  name: 'Lee',
  address: 'Seoul'
};

// 객체가 상속받은 모든 프로토타입의 프로퍼티를 열거하지만 [[Enumerable]] false인 프로퍼티는 제외
// 문자열인 프로퍼티 키에 대해서는 정렬 실시
for (const key in person) {
  console.log(`${key}: ${person[key]}`);
}

// name: Lee
// address: Seoul
````

<br>

배열 순회는 for ... in 보다는 for ... of 또는 Array.prototype.forEach 권장  

````javascript
const arr = [1, 2, 3];
arr.x = 10;

for (const i in arr) {
  console.log(arr[i]);    // 1 2 3 10
}
````

<br>

### Object.keys/values/entries 메서드  
for ... in 문은 객체 자신의 고유 프로퍼티 뿐만 아니라 상속받은 프로퍼티도 열거  
고유 프로퍼티만 열거하려면 Object.keys/values/entries 메서드 사용 권장  

<br>

````javascript
// ES8에서 도입된 Object.entries
console.log(Object.entries(person));    // [["name", "Lee"], ["address", "Seoul"]]
Object.entries(person).forEach(([key, value]) => console.log(key, value));
/*
name Lee
address Seoul
*/
````

<br>
