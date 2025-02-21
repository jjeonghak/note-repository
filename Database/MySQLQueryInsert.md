# INSERT
일반적으로 온라인 트랜잭션 서비스는 소량의 레코드를 삽입하는 형태이기 때문에 성능에 대해 고려할 부분이 많지 않음  
삽입 쿼리 문장 자체보다는 테이블 구조가 성능에 더 큰 영향 발생  
조회와 삽입 성능이 모두 좋은 테이블 구조는 없기 때문에 어느 정도 타협하면서 테이블 구조 설계  

<br>

## 고급 옵션
조회 쿼리보단 다양하진 않지만 삽입 쿼리에도 사용 가능한 기능 존재  

<br>

### INSERT IGNORE
저장하는 레코드의 프라이머리 키 또는 유니크 인덱스 칼럼값이 존재하는 경우 해당 레코드 무시  
저장하는 레코드의 칼럼이 테이블 칼럼과 호환되지 않는 경우 해당 레코드 무시  
삽입 쿼리가 에러를 발생시킨 경우 경고 수준의 메시지로 대체하고 나머지 레코드 삽입 진행  

```
mysql> INSERT INTO salaries VALUES (NULL, NULL, NULL, NULL);
ERROR 1048 (23000): Column 'emp_no' cannot be null

mysql> INSERT IGNORE INTO salaries VALUES (NULL, NULL, NULL, NULL);
Query OK, 1 row affected, 4 warnings (0.01 sec)

Warning (Code 1048): Column 'emp_no' cannot be null
Warning (Code 1048): Column 'salary' cannot be null
Warning (Code 1048): Column 'from_date' cannot be null
Warning (Code 1048): Column 'to_date' cannot be null

mysql> SELECT * FROM salaries WHERE emp_no = 0;
+--------+--------+------------+------------+
| emp_no | salary | from_date  | to_date    |
+--------+--------+------------+------------+
|      0 |      0 | 0000-00-00 | 0000-00-00 |
+--------+--------+------------+------------+
```

<br>

### INSERT ... ON DUPLICATE KEY UPDATE
프라이머리 키나 유니크 인덱스 중복이 발생하면 `UPDATE` 동작  
REPLACE 쿼리는 이와 유사하지만, 내부적으로 `DELETE + INSERT` 조합으로 동작  

```sql
INSERT INTO daily_statistic (target_date, stat_name, stat_value)
VALUES (DATE(NOW()), 'VISIT', 1)
ON DUPLICATE KEY UPDATE stat_value = stat_value + 1;
```

<br>

만약 집계 함수를 사용하려면 우회해야 가능  

```
mysql> INSERT INTO daily_statistic
         SELECT DATE(visited_at), 'VISIT', COUNT(*)
         FROM access_log
         GROUP BY DATE(visited_at)
         ON DUPLICATE KEY UPDATE stat_value = stat_value + COUNT(*)

ERROR 1111 (HY000): Invalid use of group function
```

<br>

VALUES() 함수를 사용한 우회 방법은 사장되었기 때문에 사용 금지  

```
mysql> INSERT INTO daily_statistic
         SELECT DATE(visited_at), 'VISIT', COUNT(*)
         FROM access_log
         GROUP BY DATE(visited_at)
         ON DUPLICATE KEY UPDATE stat_value = stat_value + VALUES(stat_value);

Warning (Code 1287): 'VALUES function' is deprecated and will be removed in a future release.
Please use an alias (INSERT INTO .. VALUES (...) AS alias) and replace VALUES(col) in the ON
DUPLICATE KEY UPDATE clause with alias.col instead
```

<br>

`INSERT ... SELECT ...` 형태 문법을 사용해서 뷰에 별칭 생성, 또는 레코드 자체에 별칭 생성  

```sql
## INSERT ... SELECT ... 문법
INSERT INTO daily_statistic
  SELECT target_date, stat_name, stat_value
  FORM(
    SELECT DATE(visited_at) target_date, 'VISIT' stat_name, COUNT(*) stat_value
    FROM access_log
    GROUP BY DATE(visited_at)
  ) stat
  ON DUPLICATE KEY UPDATE
    daily_statistic.stat_value = daily_statistic.stat_value + stat.stat_value;

## 레코드 별칭 
INSERT INTO daily_statistic (target_date, stat_name, stat_value)
VALUES ('2020-09-01', 'VISIT', 1),
       ('2020-09-02', 'VISIT', 1)
  AS new /* "new" 라는 이름으로 별칭 부여 */
ON DUPLICATE KEY
  UPDATE daily_statistic.stat_value = daily_statistic.stat_value + new.stat_value;

```

<br>

## LOAD DATA 명령 주의 사항
일반적으로 데이터를 빠르게 적재할 수 있는 방법으로 자주 소개  
내부적으로 MySQL 엔진과 스토리지 엔진 호출 횟수를 최소화하고, 스토리지 엔진이 직접 데이터를 적재  
- 단일 스레드 실행
- 단일 트랜잭션 실행

<br>

적재하는 데이터가 많지 않다면 큰 문제가 없음  
해당 명령이 실행된 시점부터 언두 로그가 삭제되지 못하고 유지  
가능하다면 데이터 파일을 여러 파일로 분리해서 여러 트랜잭션에 나누어 실행하는 것 권장  
만약 데이터 복사 작업이라면 `INSERT ... SELECT ...` 문장이 효율적  

<br>

## 성능을 위한 테이블 구조
INSERT 문장 성능은 쿼리 문장 자체보다 테이블 구조에 의해 결정  
대부분의 삽입 쿼리는 단일 레코드를 저장하기 때문에 문장 자체에서 튜닝할 부분이 크게 없음  

<br>

### 대량 INSERT 성능
하나의 삽입 쿼리로 수많은 레코드를 삽입하는 경우, 프라이머리 키 값 기준으로 미리 정렬해서 문장 구성하는 것 권장  

```
-- // 프라이머리 키 값으로 정렬해서 덤프된 CSV 파일
mysql> LOAD DATA INFILE '/tmp/sorted_by_primary.csv'
       INTO TABLE salaries_temp
       FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
       LINES TERMINATED BY '\n';
Query OK, 2844047 rows affected (1 min 53.11 sec)

-- // 아무런 정렬 없이 랜덤하게 덤프된 CSV 파일
mysql> LOAD DATA INFILE '/tmp/sorted_by_random.csv'
       INTO TABLE salaries_emp
       FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
       LINES TERMINATED BY '\n';
Query OK, 2844047 rows affected (4 min 5.94 sec)
```

<br>

InnoDB 스토리지 엔진은 프라이머리 키를 검색해서 레코드가 저장될 위치 탐색  
프라이머리 키가 정렬된 경우 직전 삽입된 레코드보다 항상 다음 값이 크기 때문에 마지막 페이지만 적재  
또한 세컨더리 인덱스 여부에 따라 성능 차이 발생, 많이 존재할수록 부정적  

<br>

### Auto-Increment 칼럼
조회보다 삽입에 최적화된 테이블을 생성하기 위해 두가지 요소 필요  
- 단조 증가 또는 단조 감소되는 값으로 프라이머리 키 선정
- 세컨더리 인덱스 최소화

<br>

InnoDB 스토리지 엔진을 사용하는 테이블은 자동으로 프라이머리 키로 클러스터링  
자동 증가 칼럼을 사용하면 클러스터링되지 않는 테이블 효과, 가장 빠른 삽입을 보장하는 방법  

```sql
CREATE TABLE access_log (
  id BIgINT NOT NULL AAUTO_INCREMENT,
  ip_address INT UNSIGNED,
  uri VARCHAR(200),
  ...
  visited_at DATETIME,
  PRIMARY KEY(id)
)
```

<br>

자동 증가 값의 채번을 위해서는 잠금이 필수, 이를 `AUTO-INC` 잠금  
5.7 버전까지는 기본값이 `1`이었지만, 8.0 버전부터 `2`로 변경  
복제의 바이너리 로그 포맷 기본값이 `STATEMENT`에서 `ROW`로 변경됐기 때문  
- `innodb_autoinc_lock_mode = 0`  
항상 `AUTO-INC` 잠금을 걸고 한번에 1씩만 증가된 값을 사용  
5.1 버전의 자동 증가 값 패번 방식, 서비스용에서는 사용할 필요 없음  

- `innodb_autoinc_lock_mode = 1`(Consecutive mode)  
단순히 레코드를 하나씩 삽입하는 쿼리에서 `AUTO-INC` 잠금이 아닌 뮤텍스 사용  
하지만 여러 레코드를 하나의 쿼리로 삽입하는 경우는 `AUTO-INC` 잠금을 걸고 필요한 만큼의 자동 증가값을 한번에 사용  
삽입 순서대로 채번된 자동 증가값은 일관, 연속된 번호 보유  

- `innodb_autoinc_lock_mode = 2`(Interleaved mode)  
벌크 삽입을 하는 경우에도 `AUTO-INC` 잠금을 사용하지 않음  
채번된 번호는 단조 증가하는 유니크한 번호까지만 보장  
삽입 순서와 채번된 번호의 연속성을 보장하지 않음  
하나의 쿼리에서도 연속되지 않은 번호가 발급되어 소스 서버와 레플리카 서버의 자동 증가값이 동기화되지 못할 가능성 존재  

<br>

만약 이때까지 사용된 자동 증가값을 조회하는 경우 `LAST_INSERT_ID()` 함수 지원  
`SELECT MAX(member_id) FROM ...` 명령은 상당히 잘못된 결과를 반환할 가능성 존재  
현재 커넥션 뿐만 아니라 다른 커넥션에서 증가된 값까지 조회할 수 있기 때문에 사용하지 않는 것 권장  

```
mysql> INSERT INTO tb_autoincrement VALUES (NULL, 'Georgi Fellona');
mysql> SELECT LAST_INSERT_ID();
+------------------+
| LAST_INSERT_ID() |
+------------------+
|                6 |
+------------------+
```

<br>

JDBC를 사용하는 경우 별도의 조회 쿼리 없이 자동 증가된 값을 조회 가능  

```java
int affectedRowCount = stmt.executeUpdate("INSERT INTO ...", Statement.RETURN_GENERATED_KEYS);
ResultSet rs = stmt.getGeneratedKeys();
String autoInsertedKey = (rs.next(0)) ? rs.getString(1) : null;
```

<br>
