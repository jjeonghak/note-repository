# 타입 변환과 단축 평가

### 타입 변환
의도적으로 값의 타입을 변환하는 것을 명시적 타입 변환 또는 타입 캐스팅  
의도와는 상관없이 표현식 평가 도중 엔진에 의해 변환되는 경우 암묵적 타입 변환 또는 타입 강제 변환  

<br>

### 암묵적 타입 변환
자바스크립트 엔진이 표현식을 평가할 때 의도와는 상관없이 코드의 문맥을 고려해서 변환  

````javascript
"10" + 2;    // "102"
"10" * 5;    // 50
!0;          // true
````
<br>

### 문자열 타입 변환
| 표현식 | 결과 |
|-|-|
| 0 + "" | "0" |
| 1 + "" | "1" |
| -1 + "" | "-1" |
| NaN + "" | "NaN" |
| Infinity + "" | "Infinity" |
| true + "" | "true" |
| null + "" | "null" |
| undefined + "" | "undefined" |
| (Symbol()) + "" | TypeError: Cannot convert a Symbol value to a string |
| ({}) + "" | "[object Object]" |
| Math + "" | "[object Math]" |
| [] + "" | "" |
| [10, 20] + "" | "10, 20" |
| (function(){}) + "" | "function(){}" |
| Array + "" | "function Array() { [native code] }" |

<br>

### 숫자 타입 변환
모든 피연산자는 코드 문맥상 모두 숫자 타입  

````javascript
1 - "1"      // 0
1 * "10"     // 10
1 / "one"    // NaN
````
<br>

| 표현식 | 결과 |
|-|-|
| +"" | 0 |
| +"0" | 0 |
| +"1" | 1 |
| +"string" | NaN |
| +true | 1 |
| +null | 0 |
| +undefined | NaN |
| +Symbol() | TypeError: Cannot convert a Symbol value to a number |
| +{} | NaN |
| +[] | 0 |
| +[10, 20] | NaN |
| +(function(){}) | NaN |

<br>

### 불리언 타입 변환
자바스크립트 엔진은 불리언 타입이 아닌 값을 Truthy 또는 Falsy 값으로 구분  
Falsy 값: false, undefined, null, 0, -0, NaN, ""  
Truthy 값: Falsy 값이 아닌 모든 값  

<br>

### 명시적 타입 변환
표준 빌트인 생성자 함수(String, Number, Boolean)를 new 연산자 없이 호출  
빌트인 메서드 사용  

<br>

### 문자열 타입 변환
String 생성자 함수를 new 연산자 없이 호출  
Object.prototype.toString 메서드 사용  
문자열 연결 연산자 사용  

````javascript
String(1);         // "1"
(1).toString();    // "1"
1 + "";            // "1"
````

<br>

### 숫자 타입 변환
Number 생성자 함수를 new 연산자 없이 호출  
parseInt, parseFloat 함수를 사용(문자열 한정)  
`+` 단항 산술 연산자 사용  
`*` 산술 연산자 사용  

````javascript
Number("0");            // 0
parseInt("0");          // 0
parseFloat("10.53");    // 10.53
+"10.53";               // 10.53
"10.53" * 1;            // 10.53
````

<br>

### 불리언 타입 변환
Boolean 생성자 함수를 new 연산자 없이 호출  
! 부정 논리 연산자 두번 사용  

````javascript
Boolean("x");    // true
!!"x";           // true
````

<br>

### 단축 평가
표현식을 평가하는 도중 평가 결과가 확정된 경우 나머지 평가 과정을 생략  
단축 평가 사용시 if 문 대체 가능  

<br>

### 논리 연산자를 사용한 단축 평가
논리 연산자 표현식(&&, ||)의 평가 결과는 불리언 값이 아닐 가능성 존재  
논리 연산의 결과를 결정하는 피연산자 타입을 그대로 반환  

````javascript
"Cat" && "Dog";    // "Dog"
false && "Dog";    // false

"Cat" || "Dog";    // "Cat"
false || "Dog";    // "Dog"
````

<br>

### 객체 null, undefined 가드
타입 에러 방지를 위해 단축 평가 사용  

````javascript
// 단축 평가 기본값 설정
function getStringLength(str) {
  str = str || "";
  return str.length;
}

// ES6 매개변수 기본값 설정
function getStringLength(str = "") {
  return str.length;
}
````

<br>

### 옵셔널 체이닝 연산자
ES11에서 도입  
연산자 ?.는 좌항의 피연산자가 null 또는 undefined인 경우 undefined 반환  
위의 상황이 아닌 경우 우항 프로퍼티 참조  

````javascript
var elem = null;
var value = elem?.value;
console.log(value);         // undefined
````

연산자 &&는 좌황 피연산자가 false로 평가되는 Falsy 값(false, undefined, null, 0, -0, NaN, '')인 경우 좌항 피연산자 반환

````javascript
var str = '';
var length = str && str.length;
console.log(length);               // ''
````

&& 연산자와는 다르게 ?. 연산자는 Falsy 값이라도 null, undefined가 아니면 우항 피연산자 반환

<br>

### null 병합 연산자
ES11에서 도입  
연산자 ??는 좌항의 피연산자가 null, undefined인 경우 우항 피연산자 반환  
변수의 기본값 설정에 유용  
|| 연산자와는 다르게 ?? 연산자는 Falsy 값이라도 null, undefined가 아니면 우항 피연산자 반환  

````javascript
var foo = "" ?? "default string";
console.log(foo);                    // ""

var foo = "" || "default string";
console.log(foo);                    // "default string"
````

<br>
