# 인덱스
인덱스 특성과 치이는 물리 수준 모델링에 중요한 요소  
기존 MyISAM 스토리지 엔진에서만 제공하던 전문 검색, 위치 기반 검색 기능도 지원  
쿼리 튜닝의 기본  

<br>

## 함수 기반 인덱스
일반적인 인덱스는 칼럼의 값 일부 또는 전체에 대해서만 인덱스 생성 허용  
8.0 버전부터 칼럼의 값을 변형해서 만들어진 값에 대한 인덱스 지원  
- 가상 칼럼을 이용한 인덱스  
- 함수를 이용한 인덱스  

함수 기반 인덱스는 인덱싱할 값을 계산하는 과정의 차이만 존재하고 실제로는 B-Tree 인덱스와 동일  

<br>

### 가상 칼럼을 이용한 인덱스
두 칼럼을 합쳐서 검색하려면 두 칼럼을 합친 칼럼을 추가해야만 인덱스 추가 가능  
8.0 버전부터 가상 칼럼을 추가하고 인덱스 생성 가능  

```sql
ALTER TABLE user
ADD full_name VARCHAR(30) AS (CONCAT(fitst_name, ' ', last_name)) VIRTUAL,
ADD INDEX ix_fullname (full_name);
```

<br>

새롭게 만들어진 가상 칼럼에 대한 인덱스 실행 계획이 생성  
가상 칼럼이 `VIRTUAL` 또는 `STORED` 옵션 중 어떤 옵션이든 관계없이 해당 가상 칼럼의 인덱스 생성 가능  
가상 칼럼은 테이블에 새로운 칼럼을 추가하는 것과 같은 효과가 있어서 실제 테이블 구조가 변경된다는 단점 존재  

```
mysql> EXPLAIN SELECT * FROM user WHERE full_nmme = 'Matt Lee';
+----+-------------+-------+------+-------------+---------+-------+
| id | select_type | table | type | key         | key_len | Extra |
+----+-------------+-------+------+-------------+---------+-------+
|  1 | SIMPLE      | user  | ref  | ix_fullname | 1023    | NULL  |
+----+-------------+-------+------+-------------+---------+-------+
```

<br>

### 함수를 이용한 인덱스
5.7 버전에서도 사용 가능하지만 함수를 직접 인덱스 생성 구문에 사용 불가  
8.0 버전부터 테이블 구조 변경없이 함수를 직접 사용하는 인덱스 생성 가능  
함수 기반 인덱스에 명시된 표현식과 쿼리 조건절이 같아야 사용 가능  

```
mysql> CREATE TABLE user (
         user_id BIGINT,
         first_name VARCHAR(10),
         last_name VARCHAR(10),
         PRIMARY KEY (user_id),
         INDEX ix_fullname ((CONCAT(first_name, ' ', last_name)))
       );

mysql> EXPLAIN SELECT * FROM user WHERE CONCAT(first_name, ' ', last_name) = 'Matt Less';
+----+-------------+-------+------+-------------+---------+---------------+
| id | select_type | table | type | key         | key_len | ref   | Extra |
+----+-------------+-------+------+-------------+---------+---------------+
|  1 | SIMPLE      | user  | ref  | ix_fullname | 87      | const | NULL  |
+----+-------------+-------+------+-------------+---------+---------------+
```

<br>
