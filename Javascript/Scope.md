## 스코프

### 스코프
모든 식별자(변수/함수/클래스 이름 등)는 자신이 선언된 위치에 따라 유효 범위가 결정  
스코프는 식별자가 유효한 범위를 칭함  
식별자 결정이란 동일한 식별자가 다른 스코프로 존재할 경우 어떤 변수를 참조해야할지 결정하는 것  

````javascript
var x = "global";     // 첫번째 x

function foo() {
  var x = "local";    // 두번째 x
  console.log(x);     // 식별자 결정 필요
}

foo();
console.log(x);
````

<br>

동일한 스코프에 var 키워드로 중복 선언한 변수 가능  
하지만 let, const 키워드는 중복 선언 불가  

````javascript
function foo() {
  var x = 1;          // var 키워드로 변수 선언
  var x = 2;          // 자바스크립트 엔진에 의해 var 키워드 없는 것처럼 동작
  return x;
}

function bar() {
  let x = 1;          // let, const 키워드는 중복 선언 불가
  let x = 2;
  return x;
}

console.log(foo());    // 2
console.log(bar());    // SyntaxError: Identifier 'x' has already been declared
````

<br>

### 스코프 종류
| 구분 | 설명 | 스코프 | 변수 |
|-|-|-|-|
| 전역 | 코드 바깥 영역 | 전역 스코프 | 전역 변수 |
| 지역 | 함수 몸체 내부 | 지역 스코프 | 지역 변수 |

````javascript
var x = "global x";
var y = "global y";

function outer() {
  var z = "outer's local z";

  console.log(x);      // global x
  console.log(y);      // global y
  console.log(z);      // outer's local z

  function inner() {
    var x = "inner's local x";

    console.log(x);    // inner's local x
    console.log(y);    // global y
    console.log(z);    // outer's local z
  }

  inner();
}

outer();
console.log(x);        // global x
console.log(z);        // ReferenceError: z is not defined
````

<br>

### 스코프 체인
스코프도 함수와 마찬가지로 중첩 가능  
스코프 체인(scope chain)이란 함수의 중첩에 의해 계층적인 구조를 갖는 스코프를 연결한 것  
스코프 체인을 통해 변수를 참조하는 코드의 스코프에서 시작하여 상위 스코프 방향으로 변수 검색(identifier resolution)
스코프 체인은 논리적인 개념이 아닌 물리적인 실체로 존재  
렉시컬 환경(Lexical Environment)을 실제로 생성해서 변수 식별자를 키로 등록  
스코프 체인은 실행 컨텍스트의 렉시컬 환경을 단방향 연결한 것  
상위 스코프에서 유효한 변수는 하위 스코프에서 참조 가능  
하위 스코프에서 유효한 변수는 상위 스코프에서 참조 불가능  

<br>

### 함수 레벨 스코프
코드 블록이 아닌 함수에 의해서만 지역 스코프 생성  
C나 자바는 함수 몸체만이 아닌 모든 코드 블록이 지역 스코프를 생성(블록 레벨 스코프)  
하지만 var 키워드로 선언된 변수는 오직 함수 코드 블록만을 지역 스코프로 인정(함수 레벨 스코프)  

````javascript
var x = 1;
var i = 10;

if (true) {
  var x = 10;
}

for (var i = 0; i < 5; i++) {
  console.log(i);    // 0 1 2 3 4
}

console.log(x);      // 10
console.log(i);      // 5
````

<br>

### 렉시컬 스코프
함수를 어디서 호출했는지가 아닌 함수를 어디서 정의했는지에 따라 상위 스코프 결정  
함수가 호출된 위치는 상위 스코프 결정에 어떠한 영향도 주지 않음  
즉, 함수의 상위 스코프는 언제나 자신이 정의된 스코프  
이처럼 함수의 상위 스코프는 함수 정의 실행시 정적으로 결정  

````javascript
var x = 1;

function foo() {
  var x = 10;
  bar();
}

function bar() {
  console.log(x);
}
````

<br>
