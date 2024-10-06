# 프로퍼티 어트리뷰트

## 내부 슬롯과 내부 메서드
자바스크립트 엔진의 구현 알고리즘을 설명하기 위해 ECMAScript 사양에서 사용하는 의사 프로퍼티와 의사 메서드  
ECMAScript 사양에 등장하는 이중 대괄호([[...]])로 감싼 이름들  
개발자가 직접 접근해서 사용하는 객체 프로퍼티 아님  

````javascript
const o = {};

// 내부 슬롯은 자바스크립트 엔진의 내부 로직이기 때문에 직접 접근 불가
// Uncaught SyntaxError: Unexpected token '['
o.[[Prototype]]

// 단, 일부 내부 슬롯과 내부 메서드에 한하여 간접적 접근 허용
o.__proto__
````

<br>

## 프로퍼티 어트리뷰트와 프로퍼티 디스크립터 객체
자바스크립트 엔진은 프로퍼티 생성시 프로퍼티 상태를 나타내는 프로퍼티 어트리뷰트를 기본값으로 자동 정의  

<br>

### 프로퍼티 상태
1. 프로퍼티 값(`value`)
2. 값 갱신 가능 여부(`writable`)
3. 열거 가능 여부(`enumerable`)
4. 재정의 가능 여부(`configurable`)

<br>

### 프로퍼티 어트리뷰트
자바스크립트 엔진이 관리하는 내부 상태값(meta-property)  
내부슬롯 **[[Value]]**, **[[Writable]]**, **[[Enumerable]]**, **[[Configurable]]**  
`Object.getOwnPropertyDescriptor` 메서드로 간접적 접근 가능  

````javascript
const person = {
  name: 'Lee'
};

// 프로퍼티 어트리뷰트 정보를 제공하는 프로퍼티 디스크립터 객체를 반환
// {value: "Lee", writable: true, enumerable: true, configurable: true}
console.log(Object.getOwnPropertyDescriptor(person, 'name'));
````

<br>

ES8부터 도입된 `Object.getOwnPropertyDescriptors` 메서드는 모든 프로퍼티 어트리뷰트 정보 제공  

````javascript
const person = {
  name: 'Lee'
};

person.age = 20;

// 모든 프로퍼티 어트리뷰트 정보를 제공하는 프로퍼티 디스크립터 객체를 반환
/*
{
  name: {value: "Lee", writable: true, enumerable: true, configurable: true},
  age: {value: 20, writable: true, enumerable: true, configurable: true}
}
*/
console.log(Object.getOwnPropertyDescriptors(person));
````

<br>

## 데이터 프로퍼티와 접근자 프로퍼티
프로퍼티는 데이터 프로퍼티와 접근자 프로퍼티로 구분 가능  

<br>

### 데이터 프로퍼티(data property)
키-값 형태로 구성된 일반적인 프로퍼티  
이전에 살펴본 프로퍼티는 모두 데이터 프로퍼티  

| **PROPERTY*<br>*ATTRIBUTE** | **DESCRIPTOR**<br>**PROPERTY** | **DEFAULT** | **DESCRIPTION** |
|--|--|--|--|
| **[[Value]]** | value | _undefined_ |프로퍼티 키를 통해 프로퍼티 값에 접근하면 반환되는 값 <br> 프로퍼티 키를 통해 프로퍼티 값을 변경하면 **[[Value]]** 값 재할당 <br> 해당 프로퍼티 키가 존재하지 않는 경우 동적 생성 |
| **[[Writable]]** | writable | _false_ | 프로퍼티 값의 변경 가능 여부를 나타내는 불리언 값 <br> **[[Writable]]** 값이 _false_ 인 경우 해당 프로퍼티 **[[Value]]** 값 변경 불가 |
| **[[Enumerable]]** | enumerable | _false_ | 프로퍼티의 열거 가능 여부를 나타내는 불리언 값 <br> **[[Enumerable]]** 값이 _false_ 인 경우 해당 프로퍼티는 for ... in 문, Object.keys 사용 불가 |
| **[[Configurable]]** | configurable | _false_ | 프로퍼티 재정의 가능 여부를 나타내는 불리언 값 <br> **[[Configurable]]** 값이 _false_ 인 경우 프로퍼티 삭제, 어트리뷰트 값 변경 불가 <br> 단, **[[Writable]]** 값이 _true_ 인 경우 **[[Value]]** 및 **[[Writable]]** 변경은 허용 |

<br>

### 접근자 프로퍼티(accessor property)
자체적으로 값을 갖지 않고 다른 데이터 프로퍼티의 값을 읽거나 저장할 때 호출되는 접근자 함수로 구성  

| **PROPERTY*<br>*ATTRIBUTE** | **DESCRIPTOR**<br>**PROPERTY** | **DEFAULT** | **DESCRIPTION** |
|--|--|--|--|
| **[[Get]]** | get | _undefined_ | 접근자 프로퍼티를 통해 데이터 프로퍼티 값 읽을때 호출되는 접근자 함수 <br> 즉, **[[Get]]** getter 함수가 호출되고 그 결과 반환 |
| **[[Set]]** | set | _undefined_ | 접근자 프로퍼티를 통해 데이터 프로퍼티 값 저장할 때 호출되는 접근자 함수 <br> 즉, **[[Set]]** setter 함수가 호출되고 그 결과 저장 |
| **[[Enumerable]]** | enumerable | _false_ | 데이터 프로퍼티의 **[[Enumberalbe]]** 값과 동일 |
| **[[Configurable]]** | configurable | _false_ | 데이터 프로퍼티의 **[[Configurable]]** 값과 동일 |

````javascript
const person = {
  firstName: 'Ungmo',
  lastName: 'Lee',

  // 접근자 함수로 구성된 접근자 프로퍼티
  get fullName() {
    return `${this.firstName} ${this.lastName}`;
  },

  set fullName(name) {
    [this.firstName, this.lastName] = name.split(' ');
  }
};

// 데이터 프로퍼티를 통한 프로퍼티 값 참조
console.log(person.firstName + ' ' + person.lastName);

// 접근자 프로퍼티를 통한 프로퍼티 값 저장 및 조회
person.fullName = 'Heegun Lee';
console.log(person.fullName);

// 데이터 프로퍼티
const dataPropertyDescriptor = Object.getOwnPropertyDescriptor(person, 'firstName');
// {value: "Heegun", writable: true, enumerable: true, configurable: true}
console.log(dataPropertyDescriptor);

// 접근자 프로퍼티
const accessorPropertyDescriptor = Obejct.getOwnPropertyDescriptor(person, 'fullName');
// {get: f, set: f, enumerable: true, configurable: true}
console.log(accessorPropertyDescriptor);
````

<br>

## 프로퍼티 정의
프로퍼티 어트리뷰트를 명시적으로 정의 또는 기존 프로퍼티 어트리뷰트를 재정의 하는 것  

````javascript
const person = {};

// 데이터 프로퍼티 정의
Object.defineProperty(person, 'firstName', {
  value: 'Ungmo',
  writable: true,
  enumerable: true,
  configurable: true
});

// 접근자 프로퍼티 정의
Object.defineProperty(person, 'fullName', {
  get() {
    return `${this.firstName} ${this.lastName}`;
  },
  set(name) {
    [this.firstName, this.lastName] = name.split(' ');
  },
  enumerable: true,
  configurable: true
});

// 디스크립터 객체의 프로퍼티를 누락시킨 경우 undefined, false 값이 기본값
Object.defineProperty(person, 'lastName', {
  valie: 'Lee'
});

// [[Enumeralbe]] 값이 false인 경우 열거 불가능
// ["firstName"]
console.log(Object.keys(person));

// [[Writable]] 값이 false인 경우 해당 프로퍼티의 [[Value]] 값 변경 불가
// 이때 값을 변경하면 에러 발생 없이 무시
person.lastName = 'Kim';

// [[Configurable]] 값이 false인 경우 해당 프로퍼티 재정의 및 삭제 불가
// 이때 재정의하면 에러 발생, 키를 삭제하면 에러 발생 없이 무시
delete person.lastName;
// Uncaught TypeError: Cannot redefine property: lastName
Object.defineProperty(person, 'lastName', { enumerable: true});
````

<br>

`Object.defineProperties` 메서드를 사용해서 여러 개의 프로퍼티를 한번에 정의 가능

````javascript
const person = {};

Object.defineProperties(person, {
  firstName: {
    value: 'Ungmo',
    writable: true,
    enumerable: true,
    configurable: true
  },
  lastName: {
    valie: 'Lee'
  },
  fullName: {
    get() {
      return `${this.firstName} ${this.lastName}`;
    },
    set(name) {
      [this.firstName, this.lastName] = name.split(' ');
    },
    enumerable: true,
    configurable: true
  }
});
````

<br>

## 객체 변경 감지
객체는 변경 가능한 값이므로 재할당 없이 직접 변경 가능  

| **구분** | **매서드** | **프로퍼티**<br>**추가** | **프로퍼티**<br>**삭제** | **프로퍼티**<br>**값 읽기** | **프로퍼티**<br>**값 쓰기** | **프로퍼티**<br>**재정의** |
|--|--|--|--|--|--|--|
| **객체 확장 금지** | _Object.preventExtensions_ | x | o | o | o | o |
| **객체 밀봉** | _Object.seal_ | x | x | o | o | x |
| **객체 동결** | _Object.freeze_ | x | x | o | x | x |

<br>

### 객체 확장 금지
`Object.preventExtensions` 메서드는 객체의 확장을 금지  
확장이 금지된 객체는 프로퍼티 추가가 금지  
확장 가능 여부는 `Object.isExtensible` 메서드로 확인 가능  

````javascript
const person = { name: 'Lee' };

console.log(Object.isExtensible(person));    // true
Object.preventExtensions(person);            // 객체 확장 금지
console.log(Object.isExtensible(person));    // false

// 프로퍼티를 추가하면 에러 발생 없이 무시
person.age = 20;

// TypeError: Cannot define property age, object is not extensible
Object.defineProperty(person, 'age', { value: 20 });

// 프로퍼티 삭제는 가능
delete person.name;
````

<br>

### 객체 밀봉
`Object.seal` 메서드는 객체 밀봉  
프로퍼티 추가 및 삭제, 어트리뷰트 재정의 금지  
즉, 읽기와 쓰기만 가능  
밀봉 여부는 `Object.isSealed` 메서드로 확인 가능  

````javascript
const person = { name: 'Lee' };

console.log(Object.isSealed(person));    // false
Object.seal(person);                     // 객체 밀봉
console.log(Object.isSealed(person));    // true

// 밀봉된 객체는 configurable false
console.log(Object.getOwnPropertyDescriptors(person));

// 프로퍼티 추가 및 삭제시 에러 발생 없이 무시
person.age = 20;
delete person name;

// TypeError: Cannot redefine property: name
Object.defineProperty(person, 'name', { configurable: true });

// 값 갱신은 가능
person.name = 'Kim';
````

<br>

### 객체 동결
`Object.freeze` 메서드는 객체 동결  
프로퍼티 추가 및 삭제, 어트리뷰트 재정의 금지, 값 갱신 금지  
즉, 읽기만 가능  
동결 여부는 `Object.isFrozen` 메서드로 확인 가능  

````javascript
const person = { name: 'Lee' };

console.log(Object.isFrozen(person));    // false
Object.freeze(person);                   // 객체 동결
console.log(Object.isFrozen(person));    // true

// 동결된 객체는 configurable false, writable false
console.log(Object.getOwnPropertyDescriptors(person));

// 읽기를 제외한 모든 동작 무시
console.log(person.name);
````

<br>

### 불변 객체
이전까지 변경 방지 메서드들은 얕은 변경 방지(shallow only)로 직속 프로퍼티만 변경 방지  
중첩 객체까지는 영향을 주지 못함  
때문에 객체의 중첩 객체까지 변경 방지를 위해 재귀적 처리 필요  

````javascript
function deepFreeze(target) {
  if (target && typeof target === 'object' && !Object.isFrozen(target)) {
    Object.freeze(target);
    Object.keys(target).forEach(key => deepFreeze(target[key]));
  }
  return target;
}
````

<br>
