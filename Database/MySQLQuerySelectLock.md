# SELECT
상대적으로 INSERT, UPDATE 같은 작업은 거의 레코드 단위로 발생하기 때문에 성능상 문제가 되는 경우 적음  
하지만 SELECT 작업은 여러개의 테이블로부터 데이터를 조합해서 빠르게 가져와야 하기 때문에 주의 필수  

<br>

## 잠금을 사용하는 SELECT
기본적으로 InnoDB 테이블은 조회할때 레코드 잠금을 걸지 않지만, FOR SHARE, FOR UPDATE 절을 이용해서 잠금 가능  
FOR SHARE 절은 조회 쿼리로 읽은 레코드에 대해서 읽기 잠금(공유 잠금, `Shared lock`)  
FOR UPDATE 절은 조회 쿼리가 읽은 레코드에 대해서 쓰기 잠금(배타 잠금, `Exclusive lock`)  
두 잠금 옵션 모두 자동 커밋모드가 비활성화된 상태 또는 트랜잭션이 시작된 상태에서만 잠금 유지  
InnoDB 스토리지 엔진을 사용하는 테이블에서는 잠금 없는 읽기가 지원되기 때문에 잠금이 걸려있어도 단순 조회 쿼리는 대기 없이 실행  

- 단순 조회 쿼리

| 세션1 | 세션2|
|--|--|
| BEGIN; | |
| SELECT * FROM employees <br> WHERE emp_no = 10001 FOR UPDATE; | |
| | SELECT * FROM employees <br> WHERE emp_no = 10001; <br> -> 잠금 대기 없이 즉시 결과 반환 |

- 잠금 조회 쿼리

| 세션1 | 세션2|
|--|--|
| BEGIN; | |
| SELECT * FROM employees <br> WHERE emp_no = 10001 FOR UPDATE; | |
| | SELECT * FROM employees <br> WHERE emp_no = 10001 FOR SHARE; <br> -> 세션1 잠금 대기 |
| COMMIT | |
| | -> 조회 쿼리 결과 반환 |

<br>

### 잠금 테이블 선택
8.0 버전부터 잠금을 걸 테이블 선택 가능  

```sql
SELECT *
FROM employees e
  INNER JOIN dept_emp de ON de.emp_no = e.emp_no
  INNER JOIN departments d ON d.dept_no = de.dept_no
WHERE e.emp_no = 10001
FOR UPDATE OF e;
```

<br>

### NOWAIT & SKIP LOCKED
8.0 버전부터 사용 가능, 두 옵션 모두 `SELECT ... FOR UPDATE` 구문에서만 사용 가능  
NOWAIT 옵션을 사용하면 잠금 조회 쿼리가 잠금을 기다리지 않고 즉시 종료  

```
mysql> SELECT * FROM employees WHERE emp_no = 10001 FOR UPDATE NOWAIT;
ERROR 3572 (HY000): Statement aborted
  because lock(s) could not be acquired immediately and NOWAIT is set.
```

<br>

SKIP LOCKED 옵션은 잠긴 레코드는 무시하고 잠기지 않은 레코드만 조회  
조건절에 해당하는 레코드가 잠긴 경우에도 다음 레코드를 반환하기 때문에 확정적이지 않은 쿼리(`NOT-DETERMINISTIC`)  

```
mysql> SELECT * FROM salaries WHERE emp_no = 10001 LIMIT 1;
+--------+--------+------------+------------+
| emp_no | salary | from_date  | to_date    |
+--------+--------+------------+------------+
|  10001 |  60117 | 1986-06-26 | 1987-06-26 |
+--------+--------+------------+------------+

-- // 조건절에 맞는 레코드가 잠겼기 때문에, 다음 레코드를 그냥 반환
mysql> SELECT * FROM salaries
       WHERE emp_no = 10001 AND from_date = '1986-06-26'
       FOR UPDATE SKIP LOCKED LIMIT 1;
+--------+--------+------------+------------+
| emp_no | salary | from_date  | to_date    |
+--------+--------+------------+------------+
|  10001 |  62102 | 1987-06-26 | 1988-06-25 |
+--------+--------+------------+------------+
```

<br>
