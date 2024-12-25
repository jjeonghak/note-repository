# 인덱스
인덱스 특성과 치이는 물리 수준 모델링에 중요한 요소  
기존 MyISAM 스토리지 엔진에서만 제공하던 전문 검색, 위치 기반 검색 기능도 지원  
쿼리 튜닝의 기본  

<br>

## B-Tree 인덱스
가장 범용적인 목적으로 사용되는 인덱스 알고리즘  
`B+-Tree` 인덱스도 변형된 형태의 알고리즘  
인덱스 구조체 내에서 항상 정렬된 상태로 유지  

<br>

### 구조 및 특성

<img width="650" alt="b-treestructure" src="https://github.com/user-attachments/assets/6f8ce061-2f1e-422f-bdc3-43a6ec3197a5" />

최상위 루트 노드가 존재하고 그 하위에 자식 노드가 붙어있는 형태  
데이터 파일의 레코드는 정렬돼 있지 않고 임의의 순서로 저장  
인덱스는 테이블 키 칼럼만 보유, 나머지 칼럼을 조회하려면 데이터 파일에서 해당 레코드 탐색 필수  
이를 위해 리프 노드는 데이터 파일에 저장된 레코드 주소를 보유  

<br>

<img width="750" alt="b-treeleafnode" src="https://github.com/user-attachments/assets/55e0e855-e45d-4afb-8844-1442edb23c1d" />

InnoDB 스토리지 엔진은 프라이머리 키가 `ROWID` 역할 담당  
두 스토리지 엔진의 인덱스 차이점은 세컨더리 인덱스를 통해 데이터 파일의 레코드를 찾아가는 방식  
MyISAM 테이블은 세컨더리 인덱스가 물리적인 주소를 보유  
반면 InnoDB 테이블은 세컨더리 인덱스가 프라이머리 키를 주소처럼 사용하기에 논리적인 주소 보유  
즉, InnoDB 스토리지 엔진의 모든 세컨더리 인덱스 검색은 반드시 프라이머리 키를 다시 한번 검색  

<br>

### B-Tree 인덱스 키 추가 및 삭제
테이블 레코드 생성/변경/삭제하는 경우 인덱스에도 추가 작업 발생  

<br>

### 인덱스 키 추가
새로운 값이 저장될 때 스토리지 엔진에 따라 바로 인덱스에 저장될 수도 있고 아닐 수도 있음  
우선 적절한 위치를 검색한 후 리프 노드가 꽉 차있는 경우 리프 노드 분리 필요  
이런 작업 탓에 상대적으로 쓰기 작업은 많은 비용 발생  

MyISAM이나 MEMORY 스토리지 엔진의 경우 바로 새로운 값을 인덱스에 추가  
InnoDB 스토리지 엔진의 경우 지연 처리 가능  
하지만 프라이머리 키나 유니크 인덱스의 경우 중복 체크가 필요하기 때문에 즉시 처리  

<br>

### 인덱스 키 삭제
추가 작업보다 상대적으로 간단  
해당 키 값을 찾아 삭제 마크만 하면 작업 완료  
삭제 마킹된 인덱스 키 공간은 방치 또는 재활용 가능  
디스크 I/O 작업은 지연 처리 가능  

<br>

### 인덱스 키 변경
단순히 인덱스 상의 키 값만 변경하는 것 불가  
먼저 키 값을 삭제한 후 다시 새로운 키 값을 추가하는 형태로 처리  

<br>

### 인덱스 키 검색
변경 작업을 할때 인덱스 관리에 따른 추가 비용을 감수하는 이유  
100% 일치, 앞부분(left-most part) 일치, 부등호 비교 조건에 사용 가능하지만 키 값의 뒷부분 용도로는 사용 불가  
또한 함수나 연산 수행 결과로 검색하는 작업은 `B-Tree` 장점 이용 불가  

<br>

### B-Tree 인덱스 사용에 영향을 미치는 요소
칼럼의 크기, 레코드 건수, 유니크 인덱스 키 값의 갯수 등에 영향  

<br>

### 인덱스 키 값의 크기
디스크에 데이터를 저장하는 가장 기본 단위는 페이지(`Page`) 또는 블록(`Block`)  
디스크의 모든 읽기/쓰기 작업의 최소 단위  
또한 페이지는 InnoDB 스토리지 엔진 버퍼풀에서 데이터 버퍼링 기본 단위  
인덱스도 결국 페이지 단위로 관리  

<br>

일반적으로 B-Tree 자식 노드의 갯수는 가변적  
최대 자식 노드 갯수는 `인덱스 페이지 크기`와 `키 값의 크기`에 따라 결정  
페이지 크기는 `innodb_page_size` 시스템 변수로 설정 가능하지만 기본값은 `16KB`  
인덱스 키가 `16byte`, 인덱스 값이 `12byte`라고 가정하면 한 페이지에 `585개`의 키-값을 저장 가능  

<br>

### B-Tree 깊이
직접 제어할 수 있는 방법은 없음  
B-Tree 깊이는 값을 검색할 때 몇 번이나 랜덤하게 디스크를 읽어야 하는지와 직결되는 문제  
결론적으로 인덱스 키 값의 크기가 증가할수록 인덱스 페이지가 담을 수 있는 인덱스 키 갯수가 감소, 깊이가 깊어져 더 많은 디스크 읽기 발생  
가능하면 인덱스 키 값은 작게 설정하고 깊이는 4단계까지만 관리(아무리 대용량 데이터베이스라도 5단계 이상까지 깊어지는 경우는 흔치 않음)  

<br>

### 선택도(기수성)
인덱스에서 선택도(`Selectivity`) 또는 기수성(`Cardinality`)은 같은 의미로 사용  
모든 인덱스 키 값 중 유니크한 값의 수를 의미  
중복된 값이 많아질수록 기수성과 선택도 감소  
선택도가 높을수록 검색 대상이 줄어들기 때문에 빠르게 처리 가능  

<br>

```sql
SELECT * FROM tb_test WHERE country='KOREA' AND city='SEOUL';
```
country 칼럼의 유니크한 값의 갯수가 10개인 경우와 1000개인 경우의 성능 차이 발생  
인덱스가 아닌 city 칼럼의 기수성은 작업 범위에 아무런 영향을 미치지 못함  
10개인 경우 결과 레코드가 1건만 있다면, 1건의 레코드를 위해 쓸모없는 999건의 레코드를 더 읽은 것  
1000개인 경우 결과 레코드가 1건만 있다면, 1건의 레코드를 위해 쓸모없는 9건의 레코드를 더 읽은 것  

<br>

### 읽어야 하는 레코드의 건수
인덱스를 통해 테이블 레코드를 읽는 것은 높은 비용 존재  
인덱스를 거처서 읽는 것과 거치지 않고 바로 테이블을 읽는 것 중 더 효율적인 것을 판단  
일반적인 옵티마이저는 인덱스를 통해 레코드 1건을 읽는 것이 테이블에서 직접 1건을 읽는 것보다 `4 ~ 5배` 정도로 예측  
전체 테이블 레코드의 `20 ~ 25%` 레코드를 읽어야 하는 경우 직접 테이블을 읽는 것이 효율적  

<br>

### 인덱스 레인지 스캔
인덱스 접근 방법 가운데 가장 대표적인 접근 방식  
인덱스 접근 방식 중 가장 빠름  

1. 인덱스에서 조건을 만족하는 값이 저장된 위치 탐색(`index seek`)  
2. 1번에서 탐색된 위치부터 필요한 만큼 인덱스 순회(`index scan`)  
3. 2번에서 읽은 인덱스 키와 레코드 주소를 사용해 레코드가 저장된 페이지를 가져오고 최종 레코드를 조회  

<br>

<img width="600" alt="rangescan" src="https://github.com/user-attachments/assets/f0442538-9280-4265-9006-d8b382254594" />


```sql
SELECT * FROM employees WHERE first_name BETWEEN 'Ebbe' AND 'Gad';
```

인덱스 레인지 스캔은 검색해야 할 인덱스의 범위가 결정된 경우 사용하는 방식  
일단 시작 지점을 탐색한 후 그때부터 리프 노드의 레코드만 순서대로 읽음  
3번 과정이 없는 경우 커버링 인덱스라고 표현  

<br>

<img width="650" alt="rangescanwithrealdata" src="https://github.com/user-attachments/assets/260a202d-05ea-469f-bc21-3ee579251014" />


만약 커버링 인덱스가 안되는 경우 실제 데이터 레코드를 읽는 3번 과정 필수  
기본적으로 커버링 인덱스인 경우와 아닌 경우 모두 인덱스 칼럼 기준으로 정순 또는 역순으로 정렬된 상태로 레코드 반환  

<br>

```
mysql> SHOW STATUS LIKE 'Handler_%';
+--------------------+---------+
| Variable_name      | Value   |
+--------------------+---------+
| Handler_read_first | 71      |
| Handler_read_last  | 1       |
| Handler_read_key   | 567     |
| Handler_read_next  | 3447233 |
| Handler_read_prev  | 19      |
| ...                | ...     |
+--------------------+---------+
```

`Handler_read_key` 상태값은 1번 단계가 실행된 회수  
`Handler_read_next`, `Handler_read_prev` 상태값은 2번 단계로 정순/역순 기준 읽은 레코드 건수  
`Handler_read_first`, `Handler_read_last` 상태값은 첫번째/마지막 레코드를 읽은 횟수(`MIN()`, `MAX()`로만 증가)  

<br>

### 인덱스 풀 스캔
인덱스의 처음부터 끝까지 모두 읽는 방식  
대표적으로 쿼리 조건절에 사용된 칼럼이 인덱스의 첫번째 칼럼이 아닌 경우  

<img width="600" alt="fullscan" src="https://github.com/user-attachments/assets/b7568f4e-6421-444e-a16d-979b7553015d" />

일반적으로 인덱스 크기는 테이블 크기보다 작아서 직접 테이블을 처음부터 끝까지 읽는 것보다 효율적  
단 커버링 인덱스가 가능한 경우에만 해당 방식이 사용  

<br>

### 루스 인덱스 스캔
다른 DBMS의 인덱스 스킵 스캔과 유사하게 동작  
느슨하게 듬성듬성 인덱스를 읽는 방식  
인덱스 레인지 스캔과 유사하게 동작하지만 중간에 필요없는 인덱스 키 값은 무시(`skip`)  
일반적으로 `GROUP BY` 또는 `MAX()`, `MIN()` 함수 최적화에 사용  

<br>

<img width="400" alt="looseindexscan" src="https://github.com/user-attachments/assets/a25c9f01-7d28-44f2-8e12-318863809212" />


```sql
SELECT dept_no, MIN(emp_no)
FROM dept_emp
WHERE dep_no BETWEEN 'd002' AND 'd004'
GROUP BY dept_no;
```

`dept_no`, `emp_no` 두개의 칼럼으로 인덱스가 생성  
또한 이 인덱스는 (`dept_no`, `emp_no`) 조합으로 정렬까지 된 상태  
즉, WHERE 조건 범위 전체를 다 스캔할 필요없이 그룹 별로 첫 번째 레코드의 `emp_no` 값만 조회  

<br>

### 인덱스 스킵 스캔
인덱스의 핵심은 값이 정렬된 상태라는 것  
이로 인해 인덱스를 구성하는 칼럼의 순서가 매우 중요  

```sql
ALTER TABLE employees ADD INDEX ix_gender_birthdate (gender, birth_date);

## 인덱스 사용 불가 쿼리
SELECT * FROM employees WHERE birth_date >= '1965-02-01';

## 인덱스 사용 가능 쿼리
SELECT * FROM employees WHERE gender = 'M' AND birth_date >= '1965-02-01';
```

```
mysql> SET optimizer_swith='skip_scan=off';

mysql> EXPLAIN
        SELECT gender, birth_date
        FROM employees
        WHERE birth_date >= '1965-02-01';
+----+-----------+-------+---------------------+--------------------------+
| id | table     | type  | key                 | Extra                    |
+----+-----------+-------+---------------------+--------------------------+
|  1 | employees | index | ix_gender_birthdate | Using where; Using index |
+----+-----------+-------+---------------------+--------------------------+
```

<br>

<img width="400" alt="skipscan" src="https://github.com/user-attachments/assets/66459f2a-4525-4900-aa0b-4eba569e5703" />

8.0 버전부터 옵티마이저가 첫번째 칼럼을 건너뛰어서 두번째 칼럼만으로 인덱스 검색 가능하게 해주는 기능 지원  
루스 인덱스 스캔과는 다르게 `GROUP BY`가 아닌 `WHERE` 조건절 검색을 위한 기능  

<br>

```
mysql> SET optimizer_swith='skip_scan=on';

mysql> EXPLAIN
        SELECT gender, birth_date
        FROM employees
        WHERE birth_date >= '1965-02-01';
+----+-----------+-------+---------------------+----------------------------------------+
| id | table     | type  | key                 | Extra                                  |
+----+-----------+-------+---------------------+----------------------------------------+
|  1 | employees | range | ix_gender_birthdate | Using where; Using index for skip scan |
+----+-----------+-------+---------------------+----------------------------------------+
```

옵티마이저는 우선 `gender` 칼럼에서 유니크한 값을 모두 조회한 후 조건을 추가해서 쿼리를 다시 실행하는 형태로 처리  

```sql
## 옵티마이저 내부적 최적화
SELECT gender, birth_date FROM employees WHERE gender = 'M' AND birth_date >= '1965-02-01';
SELECT gender, birth_date FROM employees WHERE gender = 'F' AND birth_date >= '1965-02-01';
```

<br>

인덱스 스킵 스캔을 적용하기 위해서 조건이 필요  

- WHERE 조건절에 조건이 없는 인덱스의 선행 칼럼의 유니크한 값의 갯수가 적어야 함  
- 쿼리가 커버링 인덱스가 가능해야 함  

```
mysql> EXPLAIN SELECT * FROM employees WHERE birth_date >= '1965-02-01';
+----+-----------+------+------+-------------+
| id | table     | type | key  | Extra       |
+----+-----------+------+------+-------------+
|  1 | employees | ALL  | NULL | Using where |
+----+-----------+------+------+-------------+
```

<br>

### 다중 칼럼(Multi-column) 인덱스
실제 서비스용 데이터베이스에서는 2개 이상의 칼럼을 포함하는 인덱스가 더 많이 사용  
두개 이상 칼럼으로 구성된 인덱스를 다중 칼럼 인덱스 또는 결합 인덱스(`Concatenated Index`)라고 표현  

<img width="400" alt="concatenatedindex" src="https://github.com/user-attachments/assets/b2a7afad-fe65-4e52-95bf-dfd875b0e868" />

두번째 칼럼은 첫번째 칼럼에 의존해서 정렬  
다중 칼럼 인덱스에서는 인덱스 내에서 각 칼럼의 위치가 상당히 중요  

<br>

### B-Tree 인덱스의 정렬 및 스캔 방향
설정한 정렬 규칙에 따라 항상 오름차순/내림차순으로 정렬되어 저장  
하지만 오름차순으로 저장되어 있어도 그 인덱스를 거꾸로 끝에서부터 읽으면 내림차순  
어떤 방향으로 읽을지는 쿼리에 따라 옵티마이저가 결정  

<br>

### 인덱스의 정렬
5.7 버전까지는 칼럼 단위로 정렬 순서를 혼합해서 인덱스 생성 불가  
8.0 버전부터는 정렬 순서를 혼합한 인덱스 생성 가능  

```sql
CREATE INDEX ix_teamname_userscore ON employees (team_name ASC, user_score DESC);
```

<br>

### 인덱스 스캔 방향
인덱스 생성 시점에 오름차순/내림차순 정렬이 결정되지만 인덱스를 사용하는 시점에 인덱스를 읽는 방향이 결정  

<br>

<img width="450" alt="indexscandirection" src="https://github.com/user-attachments/assets/187a2d1d-3cb3-4537-97a6-a03fc18fdfdd" />

```sql
SELECT * FROM employees ORDER BY first_name DESC LIMIT 5;
SELECT * FROM employees WHERE first_name >= 'Anneke' ORDER BY first_name ASC LIMIT 1;
```

<br>

### 내림차순 인덱스
오름차순 인덱스로 역순 스캔이 가능한데 내림차순 인덱스는 왜 필요한가  

```
mysql> CREATE TABLE t1 (
         tid INT NOT NULL AUTO_INCREMENT,
         TABLE_NAME VARCHAR(64),
         COLUMN_NAME VARCHAR(64),
         ORDINAL_POSITION INT,
         PRIMARY KEY(tid)
       ) ENGINE=InnoDB;

mysql> INSERT INTO t1
        SELECT NULL, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION
        FROM information_schema.COLUMNS;

-- // 12번 실행
mysql> INSERT INTO t1
        SELECT NULL, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION
        FROM t1;

mysql> SELECT COUNT(*) FROM t1;
+----------+
| COUNT(*) |
+----------+
| 12619776 |
+----------+

mysql> SELECT * FROM t1 ORDER BY tid ASC LIMIT 12619776,1;
1 row in set (4.15 sec)

mysql> SELECT * FROM t1 ORDER BY tid DESC LIMIT 12619776,1;
1 row in set (5.35 sec)

```

<br>

하나의 인덱스를 정순으로 읽느냐 또는 역순으로 읽느냐에 따라 성능 차이 발생  
InnoDB 스토리지 엔진에서 정순/역순 스캔은 페이지 간의 양방향 연결 고리를 통해 전진(`Forward`)/후진(`Backward`) 차이만 존재  

<br>

<img width="400" alt="pagerecordlinking" src="https://github.com/user-attachments/assets/8213a486-083c-410d-949d-c975069d98d6" />

- 페이지 내에서 인덱스 레코드가 단방향으로만 연결된 구조  
- 페이지 잠금이 인덱스 정순 스캔(`Forward Index Scan`)에 적합한 구조  

<br>

### B-Tree 인덱스의 가용성과 효율성


















