# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## ENUM과 SET
모두 문자열 값을 내부적으로 숫자 값으로 매핑해서 관리하는 타입  
실제 데이터베이스에는 이미 인코딩된 알파벳이나 숫자 값만 저장되므로 그 의미를 바로 파악하기 쉽지 않음  

<br>

### ENUM
테이블 구조(메타 데이터)에 나열된 목록 중 하나의 값 보유 가능  
가장 큰 용도는 코드화된 값을 관리하는 것  
실제로 값을 저장할 때는 사용자로부터 요청된 문자열이 아닌 그 값에 매핑된 정수값을 사용  
최대 아이템 개수는 65535개이며, 아이템 개수가 255개 미만이면 저장 공간으로 1byte 사용하고 그 이상인 경우 2byte 사용  
매핑되는 정수값은 일반적으로 테이블 정의에 나열된 문자열 순서대로 1부터 할당(빈문자열은 항상 0)  

```
mysql> CREATE TABLE tb_enum (fd_enum ENUM('PROCESSING', 'FAILURE', 'SUCCESS'));
mysql> INSERT INTO tb_enum VALUES ('PROCESSING'), ('FAILURE');
mysql> SELECT * FROM tb_enum;
+------------+
| fd_enum    |
+------------+
| PROCESSING |
| FAILURE    |
+------------+

-- // ENUM, SET 타입의 칼럼에 숫자 연산시 저장된 숫자 값으로 연산 실행
mysql> SELECT fd_enum*1 AS fd_enum_real_value FROM tb_enum;
+--------------------+
| fd_enum_real_value |
+--------------------+
|                  1 |
|                  2 |
+--------------------+

mysql> SELECT * FROM tb_enum WHERE fd_enum = 1;
+------------+
| fd_enum    |
+------------+
| PROCESSING |
+------------+

mysql> SELECT * FROM tb_enum WHERE fd_enum = 'PROCESSING';
+------------+
| fd_enum    |
+------------+
| PROCESSING |
+------------+
```

<br>

하지만 새로운 값을 추가해야 하는 경우 테이블 구조를 변경 필수  
5.6 버전부터 새로 추가하는 아이템이 제일 마지막으로 추가되는 형태라면 리빌드 없이 메타 데이터 변경만으로 즉시 완료  

```sql
ALTER TABLE tb_enum MODIFY fd_enum ENUM('PROCESSING', 'FAILURE', 'SUCCESS', 'REFUND'), ALGORITHM=INSTANT;
ALTER TABLE tb_enum MODIFY fd_enum ENUM('PROCESSING', 'FAILURE', 'REFUND', 'SUCCESS'), ALGORITHM=COPY, LOCK=SHARED;
```

<br>

정렬은 문자열 값 기준으로 정렬되지 않고 매핑된 코드 값으로 정렬 수행(문자열 타입이 아닌 정수타입)  
만약 문자열 값으로 강제 정렬하는 경우 `CAST()` 함수를 사용해 변환한 후 정렬  

```
mysql> SELECT fd_enum*1 AS real_value, fd_enum FROM tb_enum ORDER BY fd_enum;
+------------+------------+
| real_value | fd_enum    |
+------------+------------+
|          1 | PROCESSING |
|          2 | FAILURE    |
+------------+------------+

mysql> SELECT fd_enum*1 AS real_value, fd_enum FROM tb_enum ORDER BY CAST(fd_enum AS CHAR);
+------------+------------+
| real_value | fd_enum    |
+------------+------------+
|          2 | FAILURE    |
|          1 | PROCESSING |
+------------+------------+
```

<br>

### SET
테이블의 구조에 정의된 아이템을 정수값으로 매핑해서 저장하는 방식은 동일  
하나의 칼럼에 1개 이상의 값을 저장 가능, 내부적으로 `BIT-OR` 연산을 거쳐 1개 이상 선택된 값 저장  
실제 여러 개의 값을 저장하는 공간을 가지는 것은 아님  

```
mysql> CREATE TABLE tb_set(fd_set SET('TENNIS', 'SOCCER', 'GOLF', 'TABLE_TENNIS', 'BASKETBALL'));
mysql> INSERT INTO tb_set (fd_set) VALUES ('SOCCER'), ('GOLF,TENNIS');

mysql> SELECT * FROM tb_set;
+-------------+
| fd_set      |
+-------------+
| SOCCER      |
| TENNIS,GOLF |
+-------------+

mysql> SELECT * FROM tb_set WHERE FIND_IN_SET('GOLF', fd_set);
+-------------+
| fd_set      |
+-------------+
| TENNIS,GOLF |
+-------------+

mysql> SELECT * FROM tb_set WHERE FIND_IN_SET('GOLF', fd_set) >= 1;
+-------------+
| fd_set      |
+-------------+
| TENNIS,GOLF |
+-------------+

mysql> SELECT * FROM tb_set WHERE fd_set LIKE '%GOLF%';
+-------------+
| fd_set      |
+-------------+
| TENNIS,GOLF |
+-------------+
```

<br>

동등 비교를 위해서는 칼럼에 저장된 순서대로 문자열 나열 필수  
해당 비교를 제외하곤 인덱스 사용 불가  

```
mysql> SELECT * FROM tb_set WHERE fd_set = 'TENNIS,GOLF';
+-------------+
| fd_set      |
+-------------+
| TENNIS,GOLF |
+-------------+

mysql> SELECT * FROM tb_set WHERE fd_set = 'GOLF,TENNIS';
Empty set (0.00 sec)
```

<br>

기존 타입에 정의된 아이템 중간에 새로운 아이템을 추가하는 경우 테이블 읽기 잠금과 리빌드 작업 필수  
아이템 갯수가 8개씩 증가할때 마다 저장공간 1byte씩 증가  
저장공간 크기가 변경되는 경우 읽기 잠금 및 테이블 리빌드 작업 필수  

```
mysql> ALTER TABLE tb_set MODIFY fd_set SET('TENNIS', 'e-SPORTS'), ALGORITHM=COPY, LOCK=SHARED;
mysql> ALTER TABLE tb_set MODIFY fd_set SET(
         'TENNIS', 'SOCCER', 'GOLF', 'TABLE_TENNIS', 'BASKETBALL', 'BILLIARD', 'e-SPORTS', 'SCUBA_DIVING', 'SWIMMING'
       ), ALGORITHM=INSTANT;
ERROR 1846 (0A000): ALGORITHM=INSTANT is not supported. Reason: Cannot change column type
INPLACE. Try ALGORITHM=COPY/INPLACE.
```

<br>
