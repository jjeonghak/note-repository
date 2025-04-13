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
























