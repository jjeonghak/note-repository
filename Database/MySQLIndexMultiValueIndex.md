# 인덱스
인덱스 특성과 치이는 물리 수준 모델링에 중요한 요소  
기존 MyISAM 스토리지 엔진에서만 제공하던 전문 검색, 위치 기반 검색 기능도 지원  
쿼리 튜닝의 기본  

<br>

## 멀티 밸류 인덱스
전문 검색 인덱스를 제외한 모든 인덱스는 레코드 1건이 1개의 인덱스 키 값을 보유  
멀티 밸류 인덱스는 하나의 데이터 레코드가 여러 개의 키 값을 보유 가능  
일반적인 RDBMS 기준으로 이러한 인덱스는 반정규화 기법  
하지만 최근 JSON 데이터 타입을 지원하면서 JSON의 배열 필드에 저장된 원소들에 대한 인덱스 요건 발생  

```
mysql> CREATE TABLE user (
         user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
         first_name VARCHAR(10),
         last_name VARCHAR(10),
         credit_info JSON,
         INDEX mx_creditscores ( (CAST(credit_info -> '$.credit_scores' AS UNSIGNED ARRAY)) )
       );

mysql> INSERT INTO user VALUES (1, 'Matt', 'Lee', '{"credit_scores": [360, 353, 351]}');
```

<br>

멀티 밸류 인덱스를 활용하기 위해서는 일반적인 조건 방식 사용 불가, 아래 함수 사용  
- MEMBER OF()
- JSON_CONTAINS()
- JSON_OVERLAPS()

```
mysql> SELECT * FROM user WHERE 360 MEMBER OF(credit_info -> '$.credit_scores');
+---------+------------+-----------+------------------------------------+
| user_id | first_name | last_name | credit_info                        |
+---------+------------+-----------+------------------------------------+
|       1 | Matt       | Lee       | {"credit_scores": [360, 353, 351]} |
+---------+------------+-----------+------------------------------------+

mysql> EXPLAIN SELECT * FROM user WHERE 360 MEMBER OF(credit_info -> '$.credit_scores');
+----+-------------+-------+------+----------------+---------+-------+-------------+
| id | select_type | table | type | key            | key_len | ref   | Extra       |
+----+-------------+-------+------+----------------+---------+-------+-------------+
|  1 | SIMPLE      | user  | ref  | mx_creditscore | 9       | const | Using where |
+----+-------------+-------+------+----------------+---------+-------+-------------+
```

<br>

MySQL 서버의 Worklog에는 DECIMAL, INTEGER, DATETIME, VARCHAR/CHAR 타입에 대해 멀티 밸류 인덱스 지원한다고 명시  
하지만 8.0.21 버전에서는 VARCHAR/CHAR 타입에 대해서는 지원하지 않음  

```
mysql> CREATE TABLE user (
         user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
         first_name VARHCAR(10),
         last_name VARCHAR(10),
         contacts JSON,
         INDEX mx_phone ( (CAST(contacts -> '$.phone_no' AS CHAR ARRAY)) )
       );

ERROR 1235 (42000): This version of MySQL doesn't yet support 'CAST-ing data to array of char/binary BLOBs'
```

<br>
