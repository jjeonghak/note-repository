# UPDATE와 DELETE
일반적인 온라인 트랜잭션 프로그램에서는 주로 하나의 테이블에 대해 레코드를 변경 또는 삭제하기 위해 사용  
MySQL 서버에서는 여러 테이블을 조인해서 한 개 이상 테이블의 레코드를 변경하거나 삭제하는 기능 제공  

<br>

## UPDATE ... ORDER BY ... LIMIT n
UPDATE, DELETE 쿼리는 조건절에 일치하는 모든 레코드를 처리하는 것이 일반적인 처리 방식  
특정 칼럼으로 정렬한 후 상위 몇 건만 처리하는 것도 가능  
한 번에 너무 많은 레코드를 처리하는 작업은 부정적인 영향을 주기 때문에 조금씩 잘라서 처리하는 방식  
만약 바이너리 로그 포맷이 `ROW`가 아닌 `STATEMENT`인 경우 경고 메시지 발생  

```
mysql> SET binlog_format = STATEMENT;
mysql> SELECT FROM employees ORDER BY last_name LIMIT 10;
Query OK, 10 rows affected, 1 warning (0.36 sec)

mysql> SHOW WARNINGS \G
*************************** 1. row ***************************
  Level: Note
   Code: 1592
Message: Unsafe statement written to the binary log using statement format since BINLOG_FORMAT
= STATEMENT. The statement is unsafe because it uses a LIMIT clause. This is unsafe because the
set of rows included cannot be predicted.
```

<br>

해당 경고 메시지는 정렬되어있더라도 중복된 값의 순서가 소스 서버와 레플리카 서버에서 달라질 수 있기 때문  
프라이머리키로 정렬한 경우 문제없지만 메시지는 기록  

<br>

## JOIN UPDATE
두개 이상의 테이블을 조인해서 결과 레코드를 변경 또는 삭제하는 쿼리  
조인된 테이블 중에서 특정 테이블 칼럼값을 다른 테이블의 칼럼에 업데이트해야 하는 경우 사용  
또는 양쪽 테이블에 공통으로 존재하는 레코드만 찾아서 업데이트하는 용도  
조인되는 모든 테이블에 대해 읽기 참조만 되는 테이블은 읽기 잠금, 변경되는 테이블은 쓰기 잠금  
웹 서비스 같은 OLTP 환경에서 데드락을 유발할 가능성 높음  

```sql
CREATE TABLE tb_test1 (
  emp_no INT,
  first_name VARCHAR(14),
  PRIMARY KEY(emp_no)
);

INSERT INTO tb_test1
  VALUES (10001, NULL), (10002, NULL), (10003, NULL), (10004, NULL);

UPDATE tb_test1 t1, employees e
  SET t1.first_name = e.first_name
WHERE e.emp_no = t1.emp_no;
```

<br>

GROUP BY 또는 ORDER BY 절이 필요한 경우 파생 테이블 사용  
`STRAIGH_JOIN` 키워드는 조인 키워드로 사용되지만, 조인 순서까지 결정  

```sql
ALTER TABLE departments ADD emp_count INT;

## 오류 발생
UPDATE departments d, dept_emp de
  SET d.emp_count = COUNT(*)
WHERE de.dept_no = d.dept_no
GROUP BY de.dept_no;

## 파생 테이블 사용
UPDATE departments d,
       (SELECT de.dept_no, COUNT(*) AS emp_count
        FROM dept_emp de
        GROUP BY de.dept_no) dc
  SET d.emp_count = dc.emp_count
WHERE dc.dept_no = d.dept_no;

## STRAIGHT 키워드 사용
UPDATE (SELECT de.dept_no, COuNT(*) AS emp_count
        FROM dept_emp de
        GROUP BY de.dept_no) dc
STRAIGHT_JOIN departments d ON dc.dept_no = d.dept_no
  SET d.emp_ount = dc.emp_count;

## 옵티마이저 힌트 사용
UPDATE /*+ JOIN_ORDER (dc, d) */
  (SELECT de.dept_no, COUNT(*) AS emp_count
   FROM dept_emp de
   GROUP BY de.dept_no) dc
INNER JOIN departments d ON dc.dept_no = d.dept_no
  SET d.emp_count = dc.emp_count;

## 래터럴 조인 사용
UPDATE departments d
  INNER JOIN LATERAL (
    SELECT de.dept_no, COUNT(*) AS emp_count
    FROM dept_emp de
    WHERE de.dept_no = d.dept_no
  ) dc ON dc.dept_no = d.dept_no
SET d.emp_count = dc.emp_count;
```

<br>

## 여러 레코드 UPDATE
하나의 쿼리로 여러 레코드를 업데이트하는 경우 모든 레코드를 동일한 값으로만 업데이트 가능  
8.0 버전부터 레코드 생성(`Row Constructor`) 문법을 사용해서 레코드 별로 서로 다른 값으로 업데이트 가능  
SQL 문장 내에서 임시 테이블을 생성하는 효과 가능  

```sql
CREATE TABLE user_level (
  user_id BIGINT NOT NULL,
  user_lv INT NOT NULL,
  created_at DATETIME NOT NULL,
  PRIMARY KEY (user_id)
);

UPDATE user_level ul
  INNER JOIN (VALUES ROW(1, 1), ROW(2, 4)) new_user_level (user_id, user_lv)
    ON new_user_level.user_id = ul.user_id
  SET ul.user_lv = ul.user_lv + new_user_level.user_lv;
```

<br>

## JOIN DELETE
단일 테이블 삭제 쿼리와는 조금 다른 문법  
DELETE와 FROM 절 사이에 삭제할 테이블을 명시  

```sql
DELETE e
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no AND de.dept_no = d.dept_no AND d.dept_no = 'd001';

DELETE e, de
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no AND de.dept_no = d.dept_no AND d.dept_no = 'd001';

DELETE e, de, d
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no AND de.dept_no = d.dept_no AND d.dept_no = 'd001';
```

<br>

JOIN UPDATE 문장과 마찬가지로 `STRAIGHT_JOIN` 키워드 사용 가능  

```sql
DELETE e, de, d
FROM departments d
  STRAIGHT_JOIN dept_emp de ON de.dept_no = d.dept_no
  STRAIGHT_JOIN employees e ON e.emp_no = de.emp_no
WHERE d.dept_no = 'd001';

DELETE /*+ JOIN_ORDER (d, de, e) */ e, de, d
FROM departments d
  INNER JOIN dept_emp de ON de.dept_no = d.dept_no
  INNER JOIN employees e ON e.emp_no = de.emp_no
WHERE d.dept_no = 'd001';
```

<br>
