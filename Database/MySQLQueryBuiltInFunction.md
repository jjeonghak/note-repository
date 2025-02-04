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
MD5, SHA 모두 비대칭형 암호화 알고리즘  
SHA() 함수는 SHA-1 암호화 알고리즘 사용, 160비트(20바이트) 해시값 반환  
MD5() 함수는 메시지 다이제스트(`Message Digest`) 알고리즘을 사용, 128비트(16바이트) 해시값 반환  
두 함수 모두 출력값은 16진수 문자열 형태이기 때문에 저장 공간이 각각 2배로 필요  
SHA() 함수는 `CHAR(40)`, MD5() 함수는 `CHAR(40)` 타입 필요  

```
mysql> SELECT MD5('abc');
+----------------------------------+
| MD5('abc')                       |
+----------------------------------+
| 900150983cd24fb0d6963f7d28e17f72 |
+----------------------------------+

mysql> SELECT SHA('abc');
+------------------------------------------+
| SHA('abc')                               |
+------------------------------------------+
| a9993e364706816aba3e25717850c26c9cd0d89d |
+------------------------------------------+

mysql> SELECT SHA2('abc', 256);
+------------------------------------------------------------------+
| SHA2('abc', 256)                                                 |
+------------------------------------------------------------------+
| ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad |
+------------------------------------------------------------------+
```

<br>

저장 공간을 원래의 16바이트와 20바이트로 줄이기 위해서 BINARY 또는 VARBINARY 타입으로 저장 가능  
이때 `BINARY(16)` 또는 `BINARY(20)`으로 정의하고 UNHEX() 함수를 이용해 이진값으로 변환해서 저장  
다시 이진값을 16진수 문자열로 돌릴때는 HEX() 함수를 사용  

```
mysql> INSERT INTO tab_binary VALUES(UNHEX(MD5('abc')), UNHEX(SHA('abc')), UNHEX(SHA2('abc', 256)));
mysql> SELECT HEX(col_md5), HEX(col_sha), HEX(col_sha2_256) FROM tab_binary \G
*************************** 1. row ***************************
     HEX(col_md5): 900150983CD24FB0D6963F7D28E17F72
     HEX(col_sha): A9993E364706816ABA3E25717850C26C9CD0B89D
HEX(col_sha2_256): BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD
```

<br>

해당 함수는 비대칭형 암호화 알고리즘이고 결과값 중복 가능성이 매우 낮음  
그렇기 때문에 길이가 긴 데이터 크기를 줄여서 인덱싱하는 용도로도 사용  

```sql
CREATE TABLE tb_accesslog (
  access_id BIGINT NOT NULL AUTO_INCREMENT,
  access_url VARCHAR(1000) NOT NULL,
  access_dttm DATETIME NOT NULL,
  PRIMARY KEY (access_id),
  INDEX ix_accessurl ( (MD5(access_url)) )
);
```

```
-- // 데이터 평문으로 삽입
mysql> INSERT INTO tb_accesslog VALUES(1, 'http://matt.com', NOW());

-- // 데이터 조회시 평문 검색은 결과 없음
mysql> SELECT * FROM tb_accesslog WHERE MD5(access_url) = 'http://matt.com';
Empty set (0.00 sec)

-- // 데이터 조회는 MD5 해시값으로 검색
mysql> SELECT * FROM tb_accesslog WHERE MD5(access_url) = MD5('http://matt.com');
+-----------+-----------------+---------------------+
| access_id | access_url      | access_dttm         |
+-----------+-----------------+---------------------+
|         1 | http://matt.com | 2020-08-23 16:38:55 |
+-----------+-----------------+---------------------+

-- // 131 바이트는 함수 결과 32 글자 바이트(32 * 4)와 메타정보(문자열 길이) 공간
mysql> EXPLAIN SELECT * FROM tb_accesslog WHERE MD5(access_url) = MD5('http://matt.com');
+----+--------------+---------------------+---------+------+-------+
| id | table        | type | key          | key_len | rows | Extra |
+----+--------------+---------------------+---------+------+-------+
|  1 | tb_accesslog | ref  | ix_accessurl | 131     |    1 | NULL  |
+----+--------------+---------------------+---------+------+-------+
```

<br>

저장 공간을 더 줄이고자 한다면 이진값을 사용  

```sql
CREATE TABLE tb_accesslog (
  access_id BIGINT NOT NULL AUTO_INCREMENT,
  access_url VARCHAR(1000) NOT NULL,
  access_dttm DATETIME NOT NULL,
  PRIMARY KEY (access_id),
  INDEX ix_accessurl ( (UNHEX(MD5(access_url))) )
);
```

```
mysql> SELECT * FROM tb_accesslog WHERE UNHEX(MD5(access_url)) = UNHEX(MD5('http://matt.com'));
+-----------+-----------------+---------------------+
| access_id | access_url      | access_dttm         |
+-----------+-----------------+---------------------+
|         1 | http://matt.com | 2020-08-23 16:38:55 |
+-----------+-----------------+---------------------+

mysql> EXPLAIN SELECT * FROM tb_accesslog WHERE UNHEX(MD5(access_url)) = UNHEX(MD5('http://matt.com'));
+----+--------------+---------------------+---------+------+--------------+
| id | table        | type | key          | key_len | rows | Extra        |
+----+--------------+---------------------+---------+------+--------------+
|  1 | tb_accesslog | ref  | ix_accessurl | 67      |    1 | Using where  |
+----+--------------+---------------------+---------+------+--------------+
```

<br>

### 처리 대기(SLEEP)
프로그래밍 언어나 쉘 스크립트 언어에서 제공하는 `sleep` 기능 수행  
디버깅 용도도 잠깐 대기하거나 의도적으로 쿼리 실행을 오래 유지할 때 상당히 유용  
초 단위 인자를 받으며, 어떠한 처리나 값을 반환하지 않음  

```sql
SELECT SLEEP(1.5) FROM employees WHERE emp_no BETWEEN 10001 AND 10010;
```

<br>

### 벤치마크(BENCHMARK)
SLEEP() 함수와 마찬가지로 성틍 테스트용으로 유용  
첫번째 인자는 반복 수행할 횟수, 두번째 인자는 반복할 표현식  
이떄 두번째 인자는 꼭 스칼라값을 반환하는 표현식  
인자로 받은 반환값은 중요하지 않고, 단지 지정한 횟수만큼 반복하는데 얼마나 시간이 소요됐는지 확인  
네트워크, 쿼리 파싱, 메모리 등의 비용을 고려 못하기 때문에 그 자체로는 큰 의미가 없음  
두 개의 동일 기능을 상대적으로 분석하는 용도  

```
mysql> SELECT BENCHMARK(10000000, MD5('abcdefghijk'));
+-----------------------------------------+
| BENCHMARK(10000000, MD5('abcdefghijk')) |
+-----------------------------------------+
|                                       0 |
+-----------------------------------------+
1 row in set (1.26 sec)
```

<br>

### IP 주소 변환(INET_ATON, INET_NTOA)
IP 주소는 4바이트의 부호없는 정수  
하지만 대부분의 DBMS에서는 VARCHAR(15) 타입에 구분자(`.`)를 이용해 저장  
MySQL에서 지원하는 IP 주소를 문자열과 정수로 변환하는 함수  
IPv4, IPv6 모두 저장하기 위해서는 BINARY(16)보다는 VARBINARY(16) 타입 사용 권장  

```
mysql> SELECT HEX(INET6_ATON('fdfe::5a55:caff:fefa:9089'));
+----------------------------------+
| FDFE0000000000005A55CAFFFEFA9089 |
+----------------------------------+

mysql> SELECT INET6_NTOA('FDFE0000000000005A55CAFFFEFA9089);
+---------------------------+
| fdfe::5a55:caff:fefa:9089 |
+---------------------------+

mysql> SELECT HEX(INET6_ATON('10.0.5.9'));
+---------+
| 0A00509 |
+---------+

mysql> SELECT INET6_NTOA(UNHEX('0A00509'));
+----------+
| 10.0.5.9 |
+----------+
```

<br>

### JSON 포맷(JSON_PRETTY)
JSON 칼럼 값을 읽기 쉬운 포맷으로 변환  

```
mysql> SELECT doc FROM employee_docs WHERE emp_no = 10005;
+------------------------------------------------------------------+
| doc                                                              |
+------------------------------------------------------------------+
| {"emp_no": 10005, "gender": "M", "salaries": [{"salary": 9145... |
+------------------------------------------------------------------+

mysql> SELECT JSON_PRETTY(doc) FROM employee_docs WHERE emp_no = 10005 \G
*************************** 1. row ***************************
JSON_PRETTY(doc): {
  "emp_no": 10005,
  "gender": "M",
  "salaries": [
    {
      "salary": 91453,
      "to_date": "2001-09-09",
      "from_date": "2000-09-09"
    },
    ...
  ],
  ...
}
```

<br>

### JSON 필드 크기(JSON_STORAGE_SIZE)
JSON 데이터는 텍스트 기반이지만 실제 디스크에 저장할때는 BSON(`Binary JSON`) 포맷을 사용  
하지만 BSON 변환시 저장 공간의 크기를 예측하기 힘들어서 JSON_STORAGE_SIZE() 함수 지원  

```
mysql> SELECT emp_no, JSON_STORAGE_SIZE(doc) FROM employee_docs LIMIT 2;
+--------+------------------------+
| emp_no | JSON_STORAGE_SIZE(doc) |
+--------+------------------------+
|  10001 |                    611 |
|  10002 |                    383 |
+--------+------------------------+
```

<br>

### JSON 필드 추출(JSON_EXTRACT)
JSON 데이터의 필드 값 추출 방법 중 가장 일반적인 방법  
첫번쨰 인자는 JSON 데이터가 저장된 칼럼 또는 JSON 데이터 자체, 두번쨰 인자는 JSON 경로  

```
mysql> SELECT emp_no, JSON_EXTRACT(doc, "$.first_name") FROM employee_docs;
+--------+-----------------------------------+
| emp_no | JSON_EXTRACT(doc, "$.first_name") |
+--------+-----------------------------------+
|  10001 | "Georgi"                          |
|    ... | ...                               |
|  10005 | "Kyoichi"                         |
+--------+-----------------------------------+

mysql> SELECT emp_no, JSON_UNQUOTE(JSON_EXTRACT(doc, "$.first_name")) FROM employee_docs;
+--------+-------------------------------------------------+
| emp_no | JSON_UNQUOTE(JSON_EXTRACT(doc, "$.first_name")) |
+--------+-------------------------------------------------+
|  10001 | Georgi                                          |
|    ... | ...                                             |
|  10005 | Kyoichi                                         |
+--------+-------------------------------------------------+

mysql> SELECT emp_no, doc->"$.first_name" FROM employee_docs LIMIT 2;
+--------+---------------------+
| emp_no | doc->"$.first_name" |
+--------+---------------------+
|  10001 | "Georgi"            |
|  10002 | "Bezalel"           |
+--------+---------------------+

mysql> SELECT emp_no, doc->>"$.first_name" FROM employee_docs LIMIT 2;
+--------+----------------------+
| emp_no | doc->>"$.first_name" |
+--------+----------------------+
|  10001 | Georgi               |
|  10002 | Bezalel              |
+--------+----------------------+
```

<br>

### JSON 오브젝트 포함 여부 확인(JSON_CONTAINS)
JSON 필드를 가지고 있는지 확인하는 함수  

```
mysql> SELECT emp_no FROM employee_docs
       WHERE JSON_CONTAIONS(doc, '{"first_name":"Christian"}');
+--------+
| emp_no |
+--------+
|  10004 |
+--------+

mysql> SELECT emp_no FROM employee_docs
       WHERE JSON_CONTAINS(doc, '"Christian"', '$.first_name');
+--------+
| emp_no |
+--------+
|  10004 |
+--------+
```

<br>

### JSON 오브젝트 생성(JSON_OBJECT)
RDBMS 칼럼의 값을 이용해 JSON 오브젝트를 생성하는 함수  

```
mysql> SELECT
         JSON_OBJECT("empNo", "emp_no"
                     "salary", "salary",
                     "fromDate", "from_date",
                     "toDate", "to_date") AS as_json
       FROM salaries LIMIT 3;
+-------------------------------------------------------------------------------------+
| as_json                                                                             |
+-------------------------------------------------------------------------------------+
| {"empNo": 10001, "salary": 60117, "toDate": "1987-06-26", "fromDate": "1986-06-26"} |
| {"empNo": 10001, "salary": 62102, "toDate": "1988-06-25", "fromDate": "1987-06-26"} |
| {"empNo": 10001, "salary": 66074, "toDate": "1989-06-25", "fromDate": "1988-06-25"} |
+-------------------------------------------------------------------------------------+
```

<br>

### JSON 칼럼으로 집계(JSON_OBJECTAGG & JSON_ARRAYAGG)
GROUP BY 절과 함계 사용되는 집계 함수  
RDBMS 칼럼의 값들을 모아 JSON 배열 또는 도큐먼트 생성  

```
mysql> SELECT dept_no, JSON_OBJECTAGG(emp_no, from_date) AS aff_manager
       FROM dept_manager
       WHERE dept_no IN ('d001', 'd002', 'd003')
       GROUP BY dept_no;
+---------+--------------------------------------------------+
| dept_no | agg_manager                                      |
+---------+--------------------------------------------------+
| d001    | {"110022": "1985-01-01", "110039": "1991-10-01"} |
| d002    | {"110085": "1985-01-01", "110114": "1989-12-17"} |
| d003    | {"110183": "1985-01-01", "110228": "1992-03-21"} |
+---------+--------------------------------------------------+

mysql> SELECT dept_no, JSON_ARRAYAGG(emp_no) as agg_manager
       FROM dept_manager
       WHERE dept_no IN ('d001', 'd002', 'd003')
       GROUP BY dept_no;
+---------+------------------+
| dept_no | agg_manager      |
+---------+------------------+
| d001    | [110022, 110039] |
| d002    | [110085, 110114] |
| d003    | [110183, 110228] |
+---------+------------------+
```

<br>

### JSON 데이터를 테이블로 변환(JSON_TABLE)
JSON 데이터의 값들을 모아서 RDBMS 테이블을 만들어 반환  
원본 테이블과 동일한 레코드 건수를 보유  

```
mysql> SELECT e2.emp_no, e2.first_name, e2.gender
       FROM employee_docs e1,
            JSON_TABLE(doc, "$" COLUMNS (emp_no, INT PATH "$.emp_no",
                                         gender CHAR(1) PATH "$.gender",
                                         first_name VARCHAR(20) PATH "$.first_name")
                      ) AS e2
       WHERE e1.emp_no IN (10001, 10002);
+--------+------------+--------+
| emp_no | first_name | gender |
+--------+------------+--------+
|  10001 | Georgi     | M      |
|  10002 | Bezalel    | F      |
+--------+------------+--------+

mysql> EXPLAIN SELECT e2.emp_no, e2.first_name, e2.gender
               FROM employee_docs e1,
                    JSON_TABLE(doc, "$" COLUMNS (emp_no, INT PATH "$.emp_no",
                                                 gender CHAR(1) PATH "$.gender",
                                                 first_name VARCHAR(20) PATH "$.first_name")
                              ) AS e2
               WHERE e1.emp_no IN (10001, 10002);
+----+-------------+-------+-------+---------+---------------------------------------------+
| id | select_type | table | type  | key     | Extra                                       |
+----+-------------+-------+-------+---------+---------------------------------------------+
|  1 | SIMPLE      | e1    | range | PRIMARY | Using where                                 |
|  1 | SIMPLE      | e2    | ALL   | NULL    | Table function: json_table; Using temporary |
+----+-------------+-------+-------+---------+---------------------------------------------+
```

<br>
