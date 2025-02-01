# 쿼리 작성 및 최적화
데이터베이스나 테이블 구조를 변경하기 위한 문장을 DDL(`Data Definition Language`)  
테이블의 데이터를 조작하기 위한 문장을 DML(`Data Manipulation Language`)  
애플리케이션은 데이터베이스에 SQL 쿼리만 전달하며, 해당 쿼리를 어떻게 처리할지는 MySQL 서버가 결정  

<br>

## MySQL 내장 함수
MySQL 함수는 기본 내장 함수와 사용자 정의 함수로 구분  
C/C++ API를 이용해서 사용자가 원하는 기능을 직접 함수로 추가 가능  
사용자 정의 함수는 스토어드 프로그램으로 작성되는 프로시저나 스토어드 함수와는 다름  

<br>

### NULL 값 비교 및 대체(IFNULL, ISNULL)
```
mysql> SELECT IFNULL(NULL, 1);
+----------------+
|              1 |
+----------------+

mysql> SELECT IFNULL(0, 1);
+----------------+
|              0 |
+----------------+

mysql> SELECT ISNULL(0);
+----------------+
|              0 |
+----------------+

mysql> SELECT ISNULL(1/0);
+----------------+
|              1 |
+----------------+
```

<br>

### 현재 시각 조회(NOW, SYSDATE)
두 함수 모두 현재의 시간을 반환하는 함수로 같은 기능 수행  
하지만 모든 NOW() 함수는 같은 값을 가지지만 SYSDATE() 함수는 호출되는 시점에 따라 결과값 상이  
만약 SYSDATE() 함수를 사용하고 있다면 `sysdate-is-now` 시스템 변수 활성화 필수  

```
mysql> SELECT NOW(), SLEEP(2), NOW();
+---------------------+----------+---------------------+
| NOW()               | SLEEP(2) | NOW()               |
+---------------------+----------+---------------------+
| 2020-08-23 14:55:20 |        0 | 2020-08-23 14:55:20 |
+---------------------+----------+---------------------+

mysql> SELECT SYSDATE(), SLEEP(2), SYSDATE();
+---------------------+----------+---------------------+
| SYSDATE()           | SLEEP(2) | SYSDATE             |
+---------------------+----------+---------------------+
| 2020-08-23 14:55:23 |        0 | 2020-08-23 14:55:25 |
+---------------------+----------+---------------------+
```

<br>

일반적인 웹 서비스에서는 특별히 SYSDATE() 함수를 사용해야할 이유가 없음  
SYSDATE() 함수는 이러한 특성 탓에 두가지 문제를 가짐  
- SYSDATE() 함수가 사용된 SQL 구문은 레플리카 서버에서 안정적으로 복제되지 못함
- SYSDATE() 함수와 비교되는 칼럼은 인덱스를 효율적으로 사용하지 못함

```
mysql> EXPLAIN
         SELECT emp_no, salary, from_date, to_date
         FROM salaries
         WHERE emp_no = 10001 AND from_date > NOW();
+----+----------+-------+---------+---------+------+-------------+
| id | table    | type  | key     | key_len | rows | Extra       |
+----+----------+-------+---------+---------+------+-------------+
|  1 | salaries | range | PRIMARY | 7       |    1 | Using where |
+----+----------+-------+---------+---------+------+-------------+

mysql> EXPLAIN
         SELECT emp_no, salary, from_date, to_date
         FROM salaries
         WHERE emp_no = 10001 AND from_date > SYSDATE();
+----+----------+------+---------+---------+------+-------------+
| id | table    | type | key     | key_len | rows | Extra       |
+----+----------+------+---------+---------+------+-------------+
|  1 | salaries | ref  | PRIMARY | 4       |   17 | Using where |
+----+----------+------+---------+---------+------+-------------+
```

<br>

### 날짜와 시간의 포맷(DATE_FROMAT, STR_TO_DATE)
DATETIME 타입 칼럼이나 값을 문자열 포맷으로 변환하는 경우 DATE_FORMAT() 사용  
반대의 경우 STR_TO_DATE() 사용  

| 지정문자 | 내용 |
|--|--|
| %Y | 4자리 연도 |
| %m | 2자리 숫자 표시의 월(01 ~ 12) |
| %d | 2자리 숫자 표시의 일자(01 ~ 31) |
| %H | 2자리 숫자 표시의 시(00 ~ 23) |
| %i | 2자리 숫자 표시의 분(00 ~ 59) |
| %s | 2자리 숫자 표시의 초(00 ~ 59) |

```
mysql> SELECT DATE(NOW(), '%Y-%m-%d %H:%i:%s') AS current_dttm;
+---------------------+
| current_dttm        |
+---------------------+
| 2020-08-23 15:00:45 |
+---------------------+

mysql> SELECT STR_TO_DATE('2020-08-23 15:06:45', '%Y-%m-%d %H:%i:%s') AS current_dttm;
+---------------------+
| current_dttm        |
+---------------------+
| 2020-08-23 15:06:45 |
+---------------------+
```

<br>

### 날짜와 시간의 연산(DATE_ADD, DATE_SUB)
특정 날짜에서 연도나 월일 또는 시간 등을 더하거나 빼는 함수  
DATE_ADD() 함수마으로 더하거나 빼는 처리 모두 가능해서 굳이 DATE_SUB 필요없음  

| 단위 | 의미 |
|--|--|
| YEAR | 연도(중간의 숫자 값은 더하거나 뺄 연수를 의미) |
| MONTH | 월(중간의 숫자 값은 더하거나 뺄 개월 수를 의미) |
| DAY | 일(중간의 숫자 값은 더하거나 뺄 일자 수를 의미) |
| HOUR | 시(중간의 숫자 값은 더하거나 뺄 시를 의미) |
| MINUTE | 분(중간의 숫자 값은 더하거나 뺄 분 수를 의미) |
| SECOND | 초(중간의 숫자 값은 더하거나 뺄 초 수를 의미) |
| MICROSECOND | 마이크로초(중간의 숫자 값은 더하거나 뺄 마이크로초 수를 의미) |
| QUARTER | 분기(중간의 숫자 값은 더하거나 뺄 분기를 의미) |
| WEEK | 주(중간의 숫자 값은 더하거나 뺄 주 수를 의미) |

```
mysql> SELECT DATE_ADD(NOW(), INTERVAL 1 DAY) AS tomorrow;
+---------------------+
| tomorrow            |
+---------------------+
| 2020-08-24 15:11:07 |
+---------------------+

mysql> SELECT DATE_ADD(NOW(), INTERVAL -1 DAY) AS yesterday;
+---------------------+
| yesterday            |
+---------------------+
| 2020-08-22 15:11:07 |
+---------------------+
```

<br>

### 타임스탬프 연산(UNIX_TIMESTAMP, FROM_UNIXTIME)
UNIX_TIMESTAMP() 함수는 '1970-01-01 00:00:00' 시점부터 경과된 초 수를 반환  
FROM_UNIXTIME() 함수는 반대로 인자로 전달한 타임스탬프 값을 DATETIME 타입으로 변환  
MySQL의 TIMESTAMP 타입은 4바이트 숫자 타입이기 때문에 `1970-01-01 00:00:01` ~ `2038-01-09 03:14:07` 날짜 값만 가능  

```
mysql> SELECT UNIX_TIMESTAMP();
+------------------+
| UNIX_TIMESTAMP() |
+------------------+
|       1598163535 |
+------------------+

mysql> SELECT UNIX_TIMESTAMP('2020-08-23 15:06:45');
+---------------------------------------+
| UNIX_TIMESTAMP('2020-08-23 15:06:45') |
+---------------------------------------+
|                            1598162805 |
+---------------------------------------+

mysql> SELECT FROM_UNIXTIME(UNIX_TIMESTAMP('2020-08-23 15:06:45'));
+------------------------------------------------------+
| FROM_UNIXTIME(UNIX_TIMESTAMP('2020-08-23 15:06:45')) |
+------------------------------------------------------+
| 2020-08-23 15:06:45                                  |
+------------------------------------------------------+
```

<br>

### 문자열 처리(RPAD, LPAD / RTRIM, LTRIM, TRIM)
RPAD(), LPAD() 함수는 문자열의 우측, 좌측에 문자를 덧붙여서 지정된 길이의 문자열로 만드는 함수  
RTRIM(), LTRIM() 함수는 문자열의 우측, 좌측에 연속된 공백 문자(space, new line, tab)를 제거하는 함수  
TRIM() 함수는 RTRIM(), LTRIM() 함수를 동시에 수행하는 함수  

```
mysql> SELECT RPAD('Close', 10, '_');
+------------------------+
| RPAD('Cloee', 10, '_') |
+------------------------+
| Cloee_____             |
+------------------------+

mysql> SELECT RTRIM('Cloee   ') AS name;
+-------+
| name  |
+-------+
| Cloee |
+-------+
```

<br>

### 문자열 결합(CONCAT)
여러 개의 문자열을 연결해서 하나의 문자열로 반환하는 함수  
비슷하지만 구분자를 넣는 경우는 CONCAT_WS() 함수 사용  
숫자 값을 인자로 전달한 경우 문자열 타입으로 자동 변환후 연결  
의도된 결과가 아닌 경우 명시적으로 CAST() 함수 사용하는 것이 안전  

```
mysql> SELECT CONCAT('Georgi', 'Christian', CAST(2 AS CHAR)) AS name;
+------------------+
| name             |
+------------------+
| GeorgiChristian2 |
+------------------+

mysql> SELECT CONCAT_WS(',', 'Georgi', 'Christian') AS name;
+------------------+
| name             |
+------------------+
| Georgi,Christian |
+------------------+
```

<br>

### GROUP BY 문자열 결합(GROUP_CONCAT)
그룹 함수 중 하나로 주로 GROUP BY 절과 함께 사용  
GROUP BY 절이 없는 경우 단 하나의 결과값만 생성  
정렬, 중복 제거 등 유용하게 사용 가능  

```
mysql> SELECT GROUP_CONCAT(dept_no) FROM departments;
+----------------------------------------------+
| GROUP_CONCAT(dept_no)                        |
+----------------------------------------------+
| d009,d005,d002,d003,d001,d004,d006,d008,d007 |
+----------------------------------------------+

mysql> SELECT GROUP_CONCAT(dept_no SEPARATOR '|') FROM departments;
+----------------------------------------------+
| GROUP_CONCAT(dept_no SEPARATOR '|')          |
+----------------------------------------------+
| d009|d005|d002|d003|d001|d004|d006|d008|d007 |
+----------------------------------------------+

mysql> SELECT GROUP_CONCAT(DISTINCT dept_no ORDER BY emp_no DESC)
       FROM dept_emp
       WHERE emp_no BETWEEN 100001 AND 100003;
+-----------------------------------------------------+
| GROUP_CONCAT(DISTINCT dept_no ORDER BY emp_no DESC) |
+-----------------------------------------------------+
| d008,d005                                           |
+-----------------------------------------------------+
```

<br>

지정한 칼럼의 값들을 연결하기 위해 제한적인 메모리 버퍼 공간 필요  
결과값이 지정된 크기를 초과하는 경우 경고 메시지 또는 에러 취급  
`group_concat_max_len` 시스템 변수로 설정 가능  
8.0 버전부터 그룹 별로 개수를 제한해서 조회 가능  

```
-- // 윈도우 함수를 이용해 최대 5개 부서만 GROUP_CONCAT 실행
mysql> SELECT GROUP_CONCAT(dept_no ORDER BY dept_name DESC)
       FROM (
         SELECT *, RANK() OVER (ORDER BY dept_no) AS rnk
         FROM departments
       ) AS x
       WHERE rnk <= 5;
+-----------------------------------------------+
| GROUP_CONCAT(dept_no ORDER BY dept_name DESC) |
+-----------------------------------------------+
| d004,d001,d003,d002,d005                      |
+-----------------------------------------------+

-- // 래터럴 조인을 이용해 부서별로 10명씩만 GROUP_CONCAT 실행
mysql> SELECT d.dept_no, GROUP_CONCAT(de2.emp_no)
       FROM departments d
       LEFT JOIN LATERAL (SELECT de.dept_no, de.emp_no
                          FROM dept_emp de
                          WHERE de.dept_no = d.dept_no
                          ORDER BY de.emp_no ASC LIMIT 5) de2 ON de2.dept_no = d.dept_no
       GROUP BY d.dept_no;
+---------+-------------------------------+
| dept_no | GROUP_CONCAT(de2.emp_no)      |
+---------+-------------------------------+
| d001    | 10017,10055,10058,10108,10140 |
| d002    | 10042,10050,10059,10080,10132 |
| ...     | ...                           |
| d009    | 10011,10038,10049,10060,10088 |
+---------+-------------------------------+
```

<br>

### 값의 비교와 대체(CASE WHEN ... THEN ... END)
CASE WHEN은 함수가 아니라 SQL 구문  
조건절이 일치할때만 THEN 이하 표현식이 실행되기 때문에 여러 방식으로 사용  

```sql
SELECT de.dept_no, e.first_name, e.gender,
       CASE WHEN e.gender = 'F' THEN
                 (SELECT s.salary fROM salaries s
                  WHERE s.emp_no = e.emp_no
                  ORDER BY from_date DESC LIMIT 1)
            ELSE 0 END AS last_female_salary
FROM dept_emp de, employees e
WHERE e.emp_no = de.emp_no AND de.dept_no = 'd001';
```

<br>

### 타입의 변환(CAST, CONVERT)
프리페어 스테이트먼트(`Prepared Statement`)를 제외하면 SQL은 텍스트 기반으로 작동  
모든 입력값이 문자열로 취급되기 때문에 명시적으로 타입 변환이 필요한 경우 사용  
CONVERT() 함수는 CAST() 함수와 비슷하지만 함수 인자 사용 규칙만 조금 상이  

```sql
SELECT CAST('1234' AS SIGNED INTEGER);
SELECT CAST(1 - 2 AS UNSIGNED);
SELECT CONVERT(1 - 2, UNSIGNED);
SELECT CONVERT('ABC' USING 'utf8mb4');
```

<br>

### 이진값과 16진수 문자열(Hex String) 변환(HEX, UNHEX)
HEX() 함수는 이진값을 사람이 읽을 수 있는 형태의 16진수 문자열로 변환하는 함수  
UNHEXT() 함수는 16진수 문자열을 읽어서 숫자가 아닌 바이너리 이진값으로 변환하는 함수  

<br>

### 암호화 및 해시 함수(MD5, SHA, SHA2)












