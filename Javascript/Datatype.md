## 데이터 타입

### 데이터 타입(data type)
값의 종류  
모든 값은 데이터 타입을 가짐  

| 구분 | 데이터타입 | 설명 |
|-|-|-|
| 원시타입 | 숫자 타입 | 숫자, 정수와 실수 구분없이 하나의 타입만 존재 |
|  | 문자열 타입 | 문자열 |
|  | 불리언 타입 | 논리적 참과 거짓 |
|  | undefined 타입 | var 키워드로 선언된 변수에 암묵적으로 할당되는 값 |
|  | null 타입 | 값이 없다는 것을 의도적으로 명시할 때 사용되는 값 |
|  | 심벌 타입 | ES6에서 추가된 7번째 타입 |
| 객체 타입 |  | 객체, 함수, 배열 등 |

<br>

### 숫자 타입
다른 언어와 다르게 하나의 숫자 타입만 존재  
모든 수를 배정밀도 64비트 부동소수점 형식의 실수로 처리  
	
````javascript
console.log(1 === 1.0);	// true

// Infinity: 양의 무한대
console.log(10 / 0);

// -Infinity: 음의 무한대
console.log(10 / -0);

// NaN(not a number): 산술 연산 불가
console.log(1 * "String");
````

<br>

### 문자열 타입
텍스트 데이터를 표현하는데 사용  
작은따옴표(''), 큰따옴표(""), 백틱(``)으로 텍스트를 감싸면 문자열  
원시타입이며 불변값  

<br>

### 템플릿 리터럴
ES6부터 새로운 문자열 표기법 도입  
멀티라인 문자열, 표현식 삽입, 태그드 템플릿 등 문자열 처리 기능 제공  

<br>

### 멀티라인 문자열(multi line string)
일반 문자열 내에서는 개행이 금지  

````javascript
// SyntaxError: Invalid or unexpected token
var str = "Hello
World.";
````

<br>

### 표현식 삽입(expression interpolation)
문자열은 문자열 연결 연산자(+)를 사용해서 연결 가능  
템플릿 리터럴 내에서는 표현식 삽입을 통해 간단히 문자열 삽입 가능  

````javascript
var first = "Ung-mo";
var last = "Lee";

console.log("My name is ${first} ${last}.");
console.log("1 + 2 = ${1 + 2}");
````

<br>

### 불리언 타입
논리적 참, 거짓을 나타내는 true, false만 존재  

<br>

### undefined 타입
undefined 타입 값은 undefined가 유일  
var 키워드로 선언한 변수는 암묵적으로 undefined로 초기화  
메모리 공간을 처음 할당할 때 쓰레기 값을 내버려두지 않고 undefined로 초기화  

<br>

### null 타입
null 타입 값은 null이 유일  
undefined와는 다르게 의도적으로 값이 없다는 것을 표현  

<br>

### 심벌 타입
ES6에서 추가된 7번째 타입으로 불변값  
주로 이름이 충돌할 위험이 없는 객체의 유일한 프로퍼티 키를 만들기 위해 사용  

````javascript
var key = Symbol("key");
console.log(typeof key);	// symbol

var obj = {};
obj[key] = "value";
console.log(obj[key]);		// value
````

<br>

### 데이터 타입의 필요성
변수에 할당되는 값의 데이터 타입에 따라 확보해야 할 메모리 공간 크기가 결정  
메모리에서 값을 조회할 때 2진수를 어떻게 해석해야하는지, 어느 크기만큼 읽어야하는지 결정  
ECMAScript 사양은 문자열과 숫자 타입 외의 데이터 타입의 크기를 명시적으로 규정 안함  
엔진 제조사의 구현에 따라 다를 가능성 존재  

<br>

### 동적 타이핑
C나 Java 같은 정적 타입 언어는 변수를 선언할 때 데이터 타입 명시 필수(명시적 타입 선언)  
정적 타입 언어는 컴파일 시점에 타입 체크 수행  
자바스크립트 변수는 어떠한 데이터 타입의 값이라도 자유롭게 할당 가능  
자바스크립트 변수는 선언이 아닌 할당에 의해 타입 결정(타입 추론)  

````javascript
var foo;
console.log(typeof foo);	// undefined

foo = 3;
console.log(typeof foo);	// number

foo = "Hello";
console.log(typeof foo);	// string

foo = true;
console.log(typeof foo);	// boolean

foo = null;
console.log(typeof foo);	// object

foo = Symbol();
console.log(typeof foo);	// symbol

foo = {};
console.log(typeof foo);	// object

foo = [];
console.log(typeof foo);	// object

foo = function () {};
console.log(typeof foo);	// function
````

<br>

### 동적 타입 언어와 변수
유연성은 높지만 신뢰성이 떨어짐  
변수는 꼭 필요한 경우에 제한적으로 사용  
변수는 유효 범위를 최대한 좁게  
전역 변수는 최대한 사용 금지  
변수보다는 상수를 사용  
변수 이름은 변수의 목적이나 의미를 파악할 수 있도록 네이밍  

<br>
