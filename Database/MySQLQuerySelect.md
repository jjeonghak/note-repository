# SELECT
상대적으로 INSERT, UPDATE 같은 작업은 거의 레코드 단위로 발생하기 때문에 성능상 문제가 되는 경우 적음  
하지만 SELECT 작업은 여러개의 테이블로부터 데이터를 조합해서 빠르게 가져와야 하기 때문에 주의 필수  

<br>

## SELECT 절의 처리 순서

```sql
SELECT s.emp_no, COUNT(DISTINCT e.first_name) AS cnt
FROM salaries s
  INNER JOIN employees e ON e.emp_no = s.emp_no
WHERE s.emp_no IN (100001, 100002)
GROUP BY s.emp_no
HAVING AVG(s.salary) > 1000
ORDER BY AVG(s.salary)
LIMIT 10;
```

<br>

<img width="600" alt="queryexecutionorder" src="https://github.com/user-attachments/assets/804e624a-445d-49d6-a918-51a0040406cc" />

<img width="600" alt="queryexecutionorder2" src="https://github.com/user-attachments/assets/0734c322-4436-4cdd-bb3c-2bdf5d965a4a" />

각 요소가 없는 경우는 가능하지만, 이 순서가 바뀌는 경우는 거의 없음  
인덱스를 이용해 처리할 때는 어떤 단계 자체가 불필요한 경우 생략  

<br>

```sql
SELECT emp_no, cnt
FROM (
      SELECT s.emp_no, COUNT(DISTINCT e.first_name) AS cnt, MAX(s.salary) AS max_salary
      FROM salaries s
        INNER JOIN employees e ON e.emp_no = s.emp_no
      WHERE s.emp_no IN (100001, 100002)
      GROUP BY s.emp_no
      HAVING MAX(s.salary) > 1000
      LIMIT 10
    ) temp_view
ORDER BY max_dalary;
```

만약 위의 실행 순서를 벗어나는 쿼리가 필요한 경우 서브쿼리로 작성된 인라인 뷰(`Inline View`) 사용  
LIMIT을 GROUP BY 전에 실행하고자 할때도 마찬가지로 서브쿼리 인라인 뷰로 먼저 적용  
인라인 뷰가 사용되면 임시 테이블이 사용되기 때문에 주의 필요  

<br>

## WHERE 절과 GROUP BY 절, ORDER BY 절의 인덱스 사용
WHERE 절의 조건뿐만 아니라 GROUP BY, ORDER BY 절도 인덱스를 이용한 빠른 처리 가능  

<br>

### 인덱스를 사용하기 위한 기본 규칙
기본적으로 인덱스를 사용하려면 인덱싱 칼럼값 자체를 변환하지 않고 그대로 사용한다는 조건 필요  
인덱싱 칼럼값을 가공한 후 조건을 사용하면 인덱스를 적절히 이용하지 못함  

```sql
SELECT * FROM salaries WHERE salary * 10 > 150000;
SELECT * FROM salaries WHERE salary > 15000;
```

<br>

만약 복잡한 연산을 수행하고 비교해야하는 경우 미리 계산된 값을 저장하도록 가상 칼럼 추가  
그 칼럼에 인덱스를 생성하거나 함수 기반 인덱스를 사용  
또한 비교 조건에서 연산자 양쪽의 두 비교 대상값은 데이터 타입이 일치해야함  

<br>

### WHERE 절의 인덱스 사용
작업 범위 결정 조건과 체크 조건 두가지 방식으로 구분  
8.0 이전 버전까지는 하나의 인덱스를 구성하는 복합 칼럼의 정렬 순서 혼합 불가  

```sql
ALTER TABLE ... ADD INDEX ix_col1234 (col_1 ASC, col_2 DESC, col_3 ASC, col_4 ASC);
```

<br>

OR 연산자를 사용한 경우 AND 연산자와 다른 처리  
각각의 조건이 인덱스 사용 가능 여부가 상이한 경우 옵티마이저는 풀 테이블 스캔을 선택  
만약 모두 인덱스 사용 가능하다면 `index_merge` 접근 방식 실행  

```sql
SELECT * FROM employees WHERE first_name = 'Kebin' OR last_name = 'Poly';
```

<br>

### GROUP BY 절의 인덱스 사용
GROUP BY 절의 각 칼럼은 비교 연산자를 가지지 않으므로 작업 범위 조건이나 체크 조건과 같이 구분할 필요 없음  
GROUP BY 절에 명시된 칼럼 순서가 인덱스를 구성하는 칼럼의 순서와 같다면 인덱스 사용 가능  

<br>

<img width="500" alt="groupbyindexrule" src="https://github.com/user-attachments/assets/b6f44e9f-b9b7-4a83-80e6-3289e71e480b" />

- GROUP BY 절에 명시된 칼럼이 인덱스 칼럼의 순서와 위치가 같아야함
- 인덱스를 구성하는 칼럼 중 뒤쪽에 있는 칼럼은 GROUP BY 절에 명시되지 않아도 되지만 앞쪽 칼럼을 필수
- GROUP BY 절에 명시된 칼럼이 하나라도 인덱스에 없으면 인덱스 사용 불가

<br>

만약 GROUP BY 절에 명시되지 않은 앞쪽 칼럼이 조건절의 동등 비교 조건으로 사용된 경우는 인덱스 사용 가능  

```sql
... WHERE col_1 = 'cost' ... GROUP BY col_2, col_3;
... WHERE col_1 = 'cost' AND col_2 = 'const' ... GROUP BY col_3, col_4;
... WHERE col_1 = 'cost' AND col_2 = 'const' AND col_3 = 'const' ... GROUP BY col_4;
```

<br>

WHERE 절과 GROUP BY 절이 혼용된 쿼리가 인덱스 처리가 가능한지는 조건절에서 동등 조건으로 사용된 칼럼을 보고 판단  

```sql
## 원본 쿼리
... WHERE col_1 = 'const' ... GROUP BY col_2, col_3;

## 조건절 동등 조건 칼럼을 그룹핑에 포함시켜본 쿼리
... WHERE col_1 = 'const' ... GROUP BY col_1, col_2, col_3;
```

<br>

### ORDER BY 절의 인덱스 사용

<img width="450" alt="orderbyindexrule" src="https://github.com/user-attachments/assets/c3216cb0-f7fc-4d4c-a51f-633966574377" />

GROUP BY 절의 요건과 거의 흡사  
추가로 정렬되는 각 칼럼의 오름차순/내림차순 옵션이 인덱스와 같거나 아예 반대인 경우에만 사용 가능  

<br>

아래 인덱스에서는 ORDER BY 절이 인덱스 사용 불가  

```sql
... ORDER BY col_2, col_3;
... ORDER BY col_1, col_3, col_2;
... ORDER BY col_1, col_2 DESC, col_3;
... ORDER BY col_1, col_3;
... ORDER BY col_1, col_2, col_3, col_4, col_5;
```

- 첫번째는 인덱스 제일 앞쪽 칼럼이 명시되지 않음
- 두번째는 칼럼 순서가 일치하지 않음
- 세번째는 다른 칼럼은 모두 인덱스와 같은 정렬이지만 두번째 칼럼이 반대 정렬
- 네번째는 앞쪽 칼럼이 모두 명시되지 않고 뒤쪽 칼럼이 명시
- 다섯번째는 인덱스에 존재하지 않는 칼럼 사용

<br>

### WHERE 조건과 ORDER BY(또는 GROUP BY) 절의 인덱스 사용

































