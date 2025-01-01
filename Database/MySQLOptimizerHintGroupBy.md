# 옵티마이저와 힌트
MySQL 서버로 요청된 쿼리 결과가 동일해도 내부적으로 처리 과정은 매우 다양  
쿼리를 최적으로 실행하기 위해 각 테이블의 데이터가 어떤 분포로 저장돼 있는지 통계 정보를 참조  
이런 기본 데이터를 비교해 최적 실행 계획을 수립하는 작업 필수  

<br>

## GROUP BY 처리
`GROOUP BY` 또한 스트리밍된 처리 불가  
인덱스를 사용하는 방법(인덱스 스캔, 루스 인덱스 스캔)과 임시 테이블 사용 방법이 존재  

<br>

### 인덱스 스캔을 이용하는 GROUP BY(타이트 인데스 스캔)
조인의 드라이빙 테이블에 속한 칼럼만 이용해 그루핑할 때 `GROUP BY` 칼럼으로 이미 인덱스가 있는 경우 그루핑 작업을 수행후 조인 처리  
이러한 그루핑 방식을 사용하는 쿼리는 실행 계획에 별도로 표기되지 않음  
인덱스를 이용해 처리된다하더라도 그룹 함수(`Aggregation function`) 등의 그룹값을 처리해야 하는 경우 임시 테이블 필요  

<br>

### 루스 인덱스 스캔을 이용하는 GROUP BY
루스 인덱스 스캔 방식은 단일 테이블에 대해 수행되는 `GROUP BY` 처리에만 사용 가능  
프리픽스 인덱스(`Prefix index`, 칼럼값의 앞쪽 일부분으로 생성된 인덱스)는 루스 인덱스 스캔 불가  
인덱스 레인지 스캔은 유니크한 값이 많을수록 성능이 향상되지만 루스 인덱스 스캔은 유니크한 값이 적을수록 성능 향상  

```
-- // 테이블 인덱스는 (`emp_no`, `from_date`) 형태로 생성  
mysql> EXPLAIN
         SELECT emp_no
         FROM salaries
         WHERE from_date = '1985-03-01'
         GROUP BY emp_no;

+----+----------+-------+---------+---------------------------------------+
| id | table    | type  | key     | Extra                                 |
+----+----------+-------+---------+---------------------------------------+
|  1 | salaries | range | PRIMARY | Using where; Using index for group-by |
+----+----------+-------+---------+---------------------------------------+
```

<br>

아래 쿼리는 루스 인덱스 스캔 불가  
```sql
## MIN() 또는 MAX() 이외의 집합 함수 사용한 경우
SELECT col1, SUM(col2) FROM tb_test GROUP BY col1;

## 그루핑 기준 칼럼이 인덱스 구성 칼럼의 왼쪽부터 일치하지 않는 경우
SELECT col1, col2 FROM tb_test GROUP BY col2, col3;

## 조회 칼럼이 그루핑 기준 칼럼과 일치하지 않는 경우
SELECT col1, col3 FROM tb_test GROUP BY col1, col2;
```

<br>

### 임시 테이블을 사용하는 GROUP BY
그루핑 기준 칼럼이 드라이빙 또는 드리븐 여부에 상관없이 인덱스를 전혀 사용하지 못하는 경우 해당 방식으로 처리  

```
mysql> EXPLAIN
         SELECT e.last_name, AVG(s.salary)
         FROM employees e, salaries s
         WHERE s.emp_no = e.emp_no
         GROUP BY e.last_name;

+----+-------+------+---------+--------+-----------------+
| id | table | type | key     | rows   | Extra           |
+----+-------+------+---------+--------+-----------------+
|  1 | e     | ALL  | NULL    | 300584 | Using temporary |
|  1 | s     | ref  | PRIMARY | 10     | NULL            |
+----+-------+------+---------+--------+-----------------+
```

8.0 버전 이전까지는 그루핑 쿼리에 암묵적인 정렬이 함께 수행(Using filesort)  
8.0 버전부터 암묵적인 정렬이 더 이상 실행되지 않음  

```
mysql> EXPLAIN
         SELECT e.last_name, AVG(s.salary)
         FROM employees e, salaries s
         WHERE s.emp_no = e.emp_no
         GROUP BY e.last_name;
         ORDER BY e.last_name;

+----+-------+------+---------+--------+---------------------------------+
| id | table | type | key     | rows   | Extra                           |
+----+-------+------+---------+--------+---------------------------------+
|  1 | e     | ALL  | NULL    | 300584 | Using temporary; Using filesort |
|  1 | s     | ref  | PRIMARY | 10     | NULL                            |
+----+-------+------+---------+--------+---------------------------------+
```

<br>
