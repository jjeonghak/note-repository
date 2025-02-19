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



















