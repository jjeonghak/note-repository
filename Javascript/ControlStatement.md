# 제어문

### 블록문
0개 이상의 문을 중괄호로 묶은 것  
코드 블록 또는 블록이라고 칭함  
자바스크립트는 블록문을 하나의 실행 단위로 취급  
블록문은 자체 종결성을 갖기 때문에 세미콜론 생략 가능  

````javascript
// 블록문
{
  var foo = 10;
}

// 제어문
var x = 1;
if (x < 10) {
  x++;
}

// 함수 선언문
function sum(a, b) {
  return a + b;
}
````

<br>

### 조건문
주어진 조건식의 평가 결과에 따라 코드 블록의 실행 제어  
if else문과 switch문으로 두 가지 조건문 제공  

<br>

### 반복문
조건식의 평가 결과가 참인 경우 코드 블록 실행  
이는 조건식이 거짓일 때까지 반복  
반복문 대신 forEach, for in, for of 문으로 대체 가능  

<br>

### 레이블 문
식별자가 붙은 문  
일반적으로 프로그램의 실행 순서를 제어하는데 사용  
중첩 for 문 외부 탈출할 때 유용, 그 밖의 경우 사용 권장 안함  

````javascript
outer: for (var i = 0; i < 3; i++) {
  for (var j = 0; j < 3; j++) {
    if (i + j === 3) break outer;
    console.log(`inner [${i}, ${j}]`);
  }
}

console.log("done");
````

<br>
