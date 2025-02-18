# SELECT
상대적으로 INSERT, UPDATE 같은 작업은 거의 레코드 단위로 발생하기 때문에 성능상 문제가 되는 경우 적음  
하지만 SELECT 작업은 여러개의 테이블로부터 데이터를 조합해서 빠르게 가져와야 하기 때문에 주의 필수  

<br>

## 윈도우 함수(Window Function)
집계 함수는 주어진 그룹별로 하나의 레코드로 묶어서 출력  
윈도우 함수는 일치하는 레코드 건수는 변하지 않고 그대로 유지  
일반적인 SQL 문장에서 하나의 레코드를 연산할 때 다른 레코드 값을 참조 불가  
예외적으로 집계 함수를 이용하면 다른 레코드 칼럼값 참조 가능  
하지만 결과 집합의 모양이 변경되기 때문에 집합을 그대로 유지하고 싶다면 윈도우 함수 사용  

<br>

### 쿼리 각 절의 실행 순서

<img width="469" alt="windowfunction" src="https://github.com/user-attachments/assets/a04bccb4-2e52-41f1-a435-5f42d915b8ed" />

윈도우 함수를 GROUP BY 칼럼 또는 WHERE 절에 사용 불가  
파생 테이블 사용시 전체 테이블이 아닌 파생 테이블에 대한 통계 결과 반환  

<br>

```
-- // 일반 윈도우 함수
mysql> SELECT emp_no, from_date, salary,
              AVG(salary) OVER() AS avg_salary
       FROM salaries
       WHERE emp_no = 10001
       LIMIT 5;
+--------+------------+--------+------------+
| emp_no | from_date  | salary | avg_salary |
+--------+------------+--------+------------+
|  10001 | 1986-06-26 |  60117 | 75388.9412 |
|  10001 | 1987-06-26 |  62102 | 75388.9412 |
|  10001 | 1988-06-25 |  66074 | 75388.9412 |
|  10001 | 1989-06-25 |  66596 | 75388.9412 |
|  10001 | 1990-06-25 |  66961 | 75388.9412 |
+--------+------------+--------+------------+

-- // 파생 테이블에 윈도우 함수
mysql> SELECT emp_no, from_date, salary,
              AVG(salary) OVER() AS avg_salary
       FROM (SELECT * FROM salaries WHERE emp_no = 10001 LIMIT 5) s2;
+--------+------------+--------+------------+
| emp_no | from_date  | salary | avg_salary |
+--------+------------+--------+------------+
|  10001 | 1986-06-26 |  60117 | 64370.0000 |
|  10001 | 1987-06-26 |  62102 | 64370.0000 |
|  10001 | 1988-06-25 |  66074 | 64370.0000 |
|  10001 | 1989-06-25 |  66596 | 64370.0000 |
|  10001 | 1990-06-25 |  66961 | 64370.0000 |
+--------+------------+--------+------------+
```

<br>

### 윈도우 함수 기본 사용법
윈도우 함수는 집계 함수와는 달리 함수 뒤에 OVER 절을 이용해 연산 대상을 파티션하기 위한 옵션 명시 가능  
이렇게 OVER 절에 의해 만들어진 그룹을 파티션(`Partition`) 또는 윈도우(`Window`)  

<br>

```
mysql> SELECT e.*,
              RANK() OVER(ORDER BY e.hire_date) AS hire_date_rank
       FROM employees e;
+--------+------------+------------+-------------+--------+------------+----------------+
| emp_no | birth_date | first_name | last_name   | gender | hire_date  | hire_date_rank |
+--------+------------+------------+-------------+--------+------------+----------------+
| 110022 | 1956-09-12 | Margareta  | Markovitch  | M      | 1985-01-01 |              1 |
| 110085 | 1959-10-28 | Ebru       | Alpin       | M      | 1985-01-01 |              1 |
| ...    | ...        | ...        | ...         | ...    | ...        | ...            |
| 111692 | 1954-10-05 | Tonny      | Butterworth | F      | 1985-01-01 |              1 |
| 110114 | 1957-03-28 | Isamu      | Legleitner  | F      | 1985-01-14 |             10 |
| 200241 | 1956-06-04 | Jaques     | Kalefeld    | M      | 1985-02-01 |             11 |
| ...    | ...        | ...        | ...         | ...    | ...        | ...            |
+--------+------------+------------+-------------+--------+------------+----------------+

mysql> SELECT de.dept_no, e.emp_no, e.first_name, e.hire_date,
              RANK() OVER(PARTITION BY de.dept_no ORDER BY e.hire_date) AS hire_date_rank
       FROM employees e
         INNER JOIN dept_emp de ON de.emp_no = e.emp_no
       ORDER BY de.dept_no, e.hire_date;
+---------+--------+------------+------------+----------------+
| dept_no | emp_no | first_name | hire_date  | hire_date_rank |
+---------+--------+------------+------------+----------------+
| d001    | 110022 | Margareta  | 1985-01-01 |              1 |
| d001    |  51773 | Eric       | 1985-02-02 |              2 |
| ...     | ...    | ...        | ...        | ...            |
| d001    | 481016 | Toney      | 1985-02-02 |              2 |
| d001    |  70562 | Morris     | 1985-02-03 |             12 |
| d001    | 226633 | Xuejun     | 2000-01-04 |          20211 |
| d002    | 110085 | Ebru       | 1985-01-01 |              1 |
| d002    | 110114 | Isamu      | 1985-01-14 |              2 |
| ...     | ...    | ...        | ...        | ...            |
+---------+--------+------------+------------+----------------+
```

<br>

윈도우 함수의 각 파티션 안에서도 연산 대상 레코드 별로 연산을 수행할 소그룹이 사용, 이를 프레임이라고 표현  
윈도우 함수는 프레임을 명시적으로 지정하지 않아도 상황에 맞게 묵시적으로 선택  

<br>

```
AGGREGATE_FUNC() OVER(<partition> <order> <frame>) AS window_func_column

frame:
  {ROWS | RANGE } {frame_start | frame_between }

frame_between:
  BETWEEN frame_start AND frame_end

frame_start, frame_end: {
  CURRENT ROW
  | UNBOUNDED PRECEDING
  | UNBOUNDED FOLLOWING
  | expr PRECEDING
  | expr FOLLOWING
}
```

프레임을 만드는 기준은 ROW, RANGE 중 하나 선택  
- `ROWS`: 레코드 위치 기준으로 프레임 생성
- `RANGE`: ORDER BY 절에 명시된 칼럼을 기준으로 값의 범위로 프레임 생성

<br>

프레임의 시작과 끝을 의미하는 키워드
- `CURRENT ROW`: 현재 레코드
- `UNBOUNDED PRECEDING`: 파티션의 첫번쨰 레코드
- `UNBOUNDED FOLLOWING`: 파티션의 마지막 레코드
- `expr PRECEDING`: 현재 레코드로부터 n번쨰 이전 레코드
- `expr FOLLOWING`: 현재 레코드로부터 n번째 이후 레코드

<br>

ROWS 구분인 경우 expr에 레코드 위치 명시, RANGE 구분인 경우 칼럼과 비교할 값 명시  
- `10 PRECEDING`: 현재 레코드로부터 10건 이전부터
- `INTERVAL 5 DAY PRECEDING`: 현재 레코드의 ORDER BY 칼럼값보다 5일 이전 레코드부터
- `5 FOLLOWING`: 현재 레코드로부터 5건 이후까지
- `INTERVAL '2:30' MINUTE_SECOND FOLLOWING`: 현재 레코드의 ORDER BY 칼럼값보다 2분 30초 이후까지

<br>

프레임을 사용하는 방법은 여러가지 존재  
- `ROWS UNBOUNDED PRECEDING`: 파티션의 첫번쨰 레코드로부터 현재 레코드까지
- `ROWS BETWEEN UNBOUND PRECEDING AND CURRENT ROW`: 파티션의 첫번쨰 레코드부터 현재 레코드까지
- `ROWS BEWEEN 1 PRECEDING AND 1 FOLLOWING`: 파티션에서 현재 레코드를 기준으로 앞 레코드부터 뒤 레코드까지
- `RANGE INTERVAL 5 DAY PRECEDING`: ORDER BY 절에 명시된 칼럼값이 5일전 레코드부터 현재 레코드까지
- `RANGE BETWEEN 1 DAY PRECEDING AND 1 DAY FOLLOWING`: ORDER BY 절에 명시된 칼럼값이 1일전 레코드부터 1일후 레코드까지

<br>

```sql
SELECT emp_no, from_date, salary

  ## 현재 레코드의 from_date 기준으로 1년 전부터 지금까지 급여 중 최소 급여
  MIN(salary) OVER(ORDER BY from_date RANGE INTERVAL 1 YEAR PRECEDING) AS min_1,

  ## 현재 레코드의 from_date 기준으로 1년 전부터 2년 후까지의 급여 중 최대 급여
  MAX(salary) OVER(ORDER BY from_date
                   RANGE BETWEEN INTERVAL 1 YEAR PRECEDING AND INTERVAL 2 YEAR FOLLOWING) AS max_1,

  ## from_date 칼럼으로 정렬 후 첫번째 레코드부터 현재 레코드까지의 평균
  AVG(salary) OVER(ORDER BY from_date ROWS UNBOUNDED PRECEDING) AS avg_1,

  ## from_date 칼럼으로 정렬 후 현재 레코드를 기준으로 이전 건부터 이후 레코드까지의 급여 평균
  AVG(salary) OVER(ORDER BY from_date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS avg_2

FROM salaries
WHERE emp_no = 10001;
```

```
+--------+------------+--------+-------+-------+------------+------------+
| emp_no | from_date  | salary | min_1 | max_1 | avg_1      | avg_2      |
+--------+------------+--------+-------+-------+------------+------------+
|  10001 | 1986-06-26 |  60117 | 60117 | 66074 | 60117.0000 | 61109.5000 |
|  10001 | 1987-06-26 |  62102 | 60117 | 66596 | 61109.5000 | 62764.3333 |
|  10001 | 1988-06-25 |  66074 | 62102 | 66961 | 62764.3333 | 64924.0000 |
|  10001 | 1989-06-25 |  66596 | 66074 | 71046 | 63722.2500 | 66543.6667 |
|  10001 | 1990-06-25 |  66961 | 66596 | 74333 | 64370.0000 | 68201.0000 |
|  10001 | 1991-06-25 |  71046 | 66961 | 75286 | 65482.6667 | 70780.0000 |
|  10001 | 1992-06-24 |  74333 | 71046 | 75994 | 66747.0000 | 73555.0000 |
|  10001 | 1993-06-24 |  75286 | 74333 | 76884 | 67814.3750 | 75204.3333 |
|  10001 | 1994-06-24 |  75994 | 75286 | 80013 | 68723.2222 | 76054.6667 |
|  10001 | 1995-06-24 |  76884 | 75994 | 81025 | 69539.3000 | 77630.3333 |
|  10001 | 1996-06-23 |  80013 | 76884 | 81097 | 70491.4545 | 79307.3333 |
|  10001 | 1997-06-23 |  81025 | 80013 | 84917 | 71369.2500 | 80711.6667 |
|  10001 | 1998-06-23 |  81097 | 81025 | 85112 | 72117.5385 | 82346.3333 |
|  10001 | 1999-06-23 |  84917 | 81097 | 85112 | 73031.7857 | 83708.6667 |
|  10001 | 2000-06-22 |  85112 | 84917 | 88958 | 73837.1333 | 85042.0000 |
|  10001 | 2001-06-22 |  85097 | 85097 | 88958 | 74540.8750 | 86389.0000 |
|  10001 | 2002-06-22 |  88958 | 85097 | 88958 | 75388.9412 | 87027.5000 |
+--------+------------+--------+-------+-------+------------+------------+
```

<br>

윈도우 함수에서 프레임이 별도로 명시되지 않으면 무조건 파티션의 모든 레코드가 연산 대상이 되는 것은 아님  
ORDER BY 절의 유무에 따라 프레임 범위가 상이  
- 사용한 경우: 묵시적 `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` 선언
- 사용하지 않은 경우: 묵시적 `RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` 선언

<br>

일부 윈도우 함수들은 프레임이 미리 고정  
이 경우 프레임을 명시하더라도 무시  
자동으로 파티션 전체가 프레임이 되는 함수
- CUME_DIST()
- DENSE_RANK()
- LAG()
- LEAD()
- NTILE()
- PRECENT_RANK()
- RANK()
- ROW_NUMBER(

<br>

### 윈도우 함수 종류
윈도우 함수에는 집계 함수와 비집계 함수 모두 사용 가능  
비집계 함수는 반드시 OVER() 절을 가지고 있어야하며 윈도우 함수로만 사용 가능  

<br>

- 집계 함수(`Aggregate Function`)

| 함수 | 설명 |
|--|--|
| AVG | 평균 값 반환 |
| BIT_AND() | AND 비트 연산 결과 반환 |
| BIT_OR() | OR 비트 연산 결과 반환 |
| BIT_XOR() | XOR 비트 연산 결과 반환 |
| COUNT() | 건수 반환 |
| JSON_ARRAYAGG() | 결과를 JSON 배열로 반환 |
| JSON_OBJECTAGG() | 결과를 JSON OBJECT 배열로 반환 |
| MAX() | 최댓값 반환 |
| MIN() | 최솟값 반환 |
| STDDEV_POP() <br> STDDEV() <br> STD() | 표준 편차값 반환 |
| STDDEV_SAMP() | 표본 표준 편차값 반환 |
| SUM() | 함계값 반환 |
| VAR_POP() <br> VARIANCE() | 표준 분산값 반환 |
| VAR_SAMP() | 표본 분산값 반환 |

<br>

- 비집계 함수(`Non-Aggregate Function`)

| 함수 | 설명 |
|--|--|
| CUME_DIST() | 누적 분포값 반환 <br> 파티션별 현재 레코드보다 작거나 같은 레코드 누적 백분율 |
| DENSE_RANK() | 랭킹값 반환 <br> 동일한 값에 대해서는 동일 순위 부여, 동일한 순위가 여러 건이어도 한 건으로 취급 |
| FIRST_VALUE | 파티션의 첫번째 레코드 값 반환 |
| LAG() | 파티션 내에서 파라미터를 이용해 n번째 이전 레코드 값 반환 |
| LAST_VALUE() | 파티션의 마지막 레코드 값 반환 |
| LEAD() | 파티션 내에서 파라미터를 이용해 n번째 이후 레코드 값 반환 |
| NTH_VALUE() | 파티션의 n번째 값 반환 |
| NTILE() | 파티션별 전체 건수를 파라미터로 n 등분한 값 반환 |
| PERCENT_RANK() | 퍼센트 랭킹값 반환 |
| RANK() | 랭킹값 반환 |
| ROW_NUMBER() | 파티션의 레코드 순번 반환 |

<br>

### DENSE_RANK()와 RANK(), ROW_NUMBER()
RNAK() 함수는 동점인 레코드가 여러 건인 경우 그 다음 레코드를 동점인 레코드 수만큼 증가시킨 순위 반환  
DENSE_RANK() 함수는 동점인 레코드를 1건으로 가정하고 순위 반환, 연속된 순위를 매김  
ROW_NUMBER() 함수는 각 레코드의 고유한 순번을 반환, 동점에 대한 고려 없이 정렬되고 연속된 레코드 번호 부여  

<br>

### LAG()와 LEAD()
LAG() 함수는 파티션 내에서 현재 레코드 기준 n번째 이전 레코드를 반환  
LEAD() 함수는 반대로 n번째 이후 레코드를 반환  

```
mysql> SELECT from_date, salary,
              LAG(salary, 5) OVER(ORDER BY from_date) AS prior_5th_value,
              LEAD(salary, 5) OVER(ORDER BY from_date) AS next_5th_value,
              LAG(salary, 5, -1) OVER(ORDER BY from_date) AS prior_5th_with_default,
              LEAD(salary, 5, -1) OVER(ORDER BY from_date) AS next_5th_with_default
       FROM salaries
       WHERE emp_no = 10001;

+------------+--------+-----------------+----------------+------------------------+-----------------------+
| from_date  | salary | prior_5th_value | next_5th_value | prior_5th_with_default | next_5th_with_default |
+------------+--------+-----------------+----------------+------------------------+-----------------------+
| 1986-06-26 |  60117 |            NULL |          71046 |                     -1 |                 71046 |
| 1987-06-26 |  62102 |            NULL |          74333 |                     -1 |                 74333 |
| 1988-06-25 |  66074 |            NULL |          75286 |                     -1 |                 75286 |
| 1989-06-25 |  66596 |            NULL |          75994 |                     -1 |                 75994 |
| 1990-06-25 |  66961 |            NULL |          76884 |                     -1 |                 76884 |
| 1991-06-25 |  71046 |           60117 |          80013 |                  60117 |                 80013 |
| 1992-06-24 |  74333 |           62102 |          81025 |                  62102 |                 81025 |
| 1993-06-24 |  75286 |           66074 |          81097 |                  66074 |                 81097 |
| 1994-06-24 |  75994 |           66596 |          84917 |                  66596 |                 84917 | 
| 1995-06-24 |  76884 |           66961 |          85112 |                  66961 |                 85112 |
| 1996-06-23 |  80013 |           71046 |          85097 |                  71046 |                 85097 |
| 1997-06-23 |  81025 |           74333 |          88958 |                  74333 |                 88958 |
| 1998-06-23 |  81097 |           75286 |           NULL |                  75286 |                    -1 |
| 1999-06-23 |  84917 |           75994 |           NULL |                  75994 |                    -1 |
| 2000-06-22 |  85112 |           76884 |           NULL |                  76884 |                    -1 |
| 2001-06-22 |  85097 |           80013 |           NULL |                  80013 |                    -1 |
| 2002-06-22 |  88958 |           81025 |           NULL |                  81025 |                    -1 |
+------------+--------+-----------------+----------------+------------------------+-----------------------+
```

<br>

### 윈도우 함수와 성능
윈도우 함수는 8.0 버전에처음 도입, 아직 인덱스 최적화가 부족한 부분 존재  
배치 프로그램이라면 사용해도 무방하지만, 온라인 트랜잭션 처리에서는 사용하지 않는 것 권장  

```
mysql> EXPLAIN SELECT MAX(from_date) OVER(PARTITION BY emp_no) AS max_from_date FROM salaries;
+----+-------------+----------+-------+-----------+---------+-----------------------------+
| id | select-type | table    | type  | key       | rows    | Extra                       |
+----+-------------+----------+-------+-----------+---------+-----------------------------+
|  1 | SIMPLE      | salaries | index | ix_salary | 2838663 | Using index; Using filesort |
+----+-------------+----------+-------+-----------+---------+-----------------------------+

mysql> EXPLAIN SELECT MAX(from_date) FROM salaries GROUP BY emp_no;
+----+-------------+----------+-------+---------+--------+--------------------------+
| id | select_type | table    | type  | key     | rows   | Extra                    |
+----+-------------+----------+-------+---------+--------+--------------------------+
|  1 | SIMPLE      | salaries | range | PRIMARY | 273035 | Using index for group-by |
+----+-------------+----------+-------+---------+--------+--------------------------+
```

<br>
