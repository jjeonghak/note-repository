# 스키마 조작(DDL)
DBMS 서버의 모든 오브젝트를 생성하거나 변경하는 쿼리는 DDL(`Data Definition Language`)  
스토어드 프로시저나 함수, DB 또는 테이블 등을 생성하거나 변경하는 대부분의 명령이 해당  
스키마를 변경하는 작업은 서버에 많은 부하를 발생  

<br>

## 온라인 DDL
5.5 버전까지 테이블의 구조를 변경하는 동안 다른 커넥션이 DML 실행 불가  
8.0 버전부터 내장된 온라인 DDL 기능으로 처리 가능  

<br>

### 온라인 DDL 알고리즘
스키마 변경하는 작업 중에 다른 커넥션이 해당 테이블의 데이터를 변경하거나 조회하는 작업을 가능하게 지원  
`old_alter_table` 시스템 변수를 이용해 온라인 DDL 사용 여부 결정, 기본값 OFF로 온라인 DDL 사용  

<br>

ALTER TABLE 명령이 실행되는 경우 아래 순서로 스키마 변경에 적합한 알고리즘 탐색  
1. `ALGORITHM=INSTANT`로 스키마 변경이 가능한지 확인 후, 가능하면 선택
2. `ALGORITHM=INPLACE`로 스키마 변경이 가능한지 확인 후, 가능하면 선택
3. `ALGORITHM=COPY` 알고리즘 선택

<br>

스키마 변경 알고리즘의 우선순위가 낮을수록 스키마 변경을 위해 더 큰 잠금과 작업 필요  
- `INSTANT`  
테이블의 데이터는 전혀 변경하지 않고 메타데이터만 변경하고 작업 완료  
테이블의 레코드 건수와는 무관하게 매우 짧은 작업 시간  

- `INPLACE`  
임시 테이블로 데이터를 복사하지 않고 스키마 변경 실행  
경우에 따라 내부적으로 테이블 리빌드 필요, 대표적으로 프라이머리 키를 추가하는 작업  
스키마 변경 중에도 테이블 읽기, 쓰기 모두 가능  

- `COPY`  
임시 테이블을 생성하고 테이블의 레코드를 모두 임시 테이블로 복사 후 임시 테이블 이름 변경해서 스키마 변경  
테이블 읽기만 가능하고 DML 실행 불가  

<br>

온라인 DDL 명령은 `ALGORITHM`과 `LOCK` 옵션을 이용해서 어떤 모드로 스키마 변경을 실행할지 결정  

```sql
ALTER TABLE salaries CHANGE to_date end_date DATE NOT NULL,
  ALGORITHM=INPLACE, LOCK=NONE;
```

<br>

`LOCK` 옵션은 `INSTANT` 알고리즘을 제외하고 사용 가능  
- `NONE`: 아무런 잠금 없음
- `SHARED`: 읽기 잠금, 스키마 변경 중 읽기는 가능하지만 쓰기는 불가능
- `EXCLUSIVE`: 쓰기 잠금, 스키마 변경 중 읽기, 쓰기 불가능

<br>

### 온라인 처리 가능한 스키마 변경

- 인덱스 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 프라이머리 키 추가 | X | O | O | O | X |
| 프라이머리 키 삭제 | X | X | O | X | X |
| 프라이머리 키 삭제 + 추가 | X | O | O | O | X |
| 세컨더리 인덱스 생성 | X | O | X | O | X | 
| 세컨더리 인덱스 삭제 | X | O | X | O | O |
| 세컨더리 인덱스 이름 변경 | X | O | X | O | O |
| 전문 검색 인덱스 생성 | X | O | X | X | X |
| 공간 검색 인덱스 생성 | X | O | X | X | X |
| 인덱스 타입 변경 | O | O | X | O | O |

<br>

- 칼럼 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 칼럼 추가 | O | O | X | O | X |
| 칼럼 삭제 | X | O | O | O | X |
| 칼럼 이름 변경 | X | O | X | O | O |
| 칼럼 순서 변경 | X | O | O | O | X |
| 칼럼 기본값 설정 | O | O | X | O | O |
| 칼럼 기본값 제거 | O | O | X | O | O |
| 칼럼 데이터 타입 변경 | X | X | O | X | X |
| VARHCHAR 타입 길이 확장 | X | O | X | O | O | 
| 자동 증가값 변경 | X | O | X | O | X | 
| 칼럼 NULLABLE 변경 | X | O | O | O | X |
| 칼럼 NOT NULL 변경 | X | O | O | O | X |
| ENUM 또는 SET 정의 변경 | O | O | X | O | O |

<br>

- 가상 칼럼 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| STORED 추가 | X | X | O | X | X |
| STORED 순서 변경 | X | X | O | X | X |
| STORED 삭제 | X | O | O | O | X |
| VIRTUAL 추가 | O | O | X | O | O |
| VIRTUAL 순서 변경 | X | X | O | X | X |
| VIRTUAL 삭제 | O | O | X | O | O |

<br>

- 외래키 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 외래키 생성 | X | O | X | O | O |
| 외래키 삭제 | X | O | X | O | O |

<br>

- 테이블 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| ROW_FORMAT 변경 | X | O | O | O | X |
| KEY_BLOCK_SIZE 변경 | X | O | O | O | X |
| STATS_PERSISTENT 설정 | X | O | X | O | O |
| CHARACTER SET 설정 | X | O | O | X | X | 
| CHARACTER SET 변경 | X | X | O | X | X |
| 테이블 최적화(OPTIMIZE) | X | O | O | O | X |
| 테이블 리빌드(FORCE 옵션) | X | O | O | O | X | 
| 테이블명 변경 | O | O | X | O | O |

<br>

- 테이블 스페이스 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 제너럴 테이블스페이스 이름 변경 | X | O | X | O | O |
| 제너럴 테이블스페이스 암호화 옵션 변경 | X | O | X | O | X |
| 테이블별 테이블스페이스 암호화 옵션 변경 | X | X | O | X | X |

<br>

- 파티션 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| PARTITION BY | X | X | O | X | X |
| ADD PARTITION | X | O | O | O (LIST, RANGE) <br> X (KEY, HASH) | X |
| DROP PARTITION | X | O | O | O (LIST, RANGE) <br> X (KEY, HASH) | X |
| 파티션의 테이블스페이스 삭제 | X | X | X | X | X |
| 파티션의 테이블스페이스 IMPORT | X | X | X | X | X |
| 파티션 TRUNCATE | X | O | O | O | X |

<br>

모든 스키마 변경 작업에 대해 온라인 DDL 지원 여부를 확인하는 것은 불가능  
`ALGORITHM`과 `LOCK` 옵션을 명시해서 강제한 후 처리하지 못하면 단순히 에러만 발생  

```
mysql> ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM=INSTANT;
ERROR 1846 (0A000): ALGORITHM=INSTANT is not supported. Reason: Dropping a primary key is not
allowed without also adding a new primary key. Try ALGORITHM=COPY/INPLACE.

mysql> ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM=INPLACE, LOCK=NONE;
ERROR 1846 (0A000): ALGORITHM=INSTANT is not supported. Reason: Dropping a primary key is not
allowed without also adding a new primary key. Try ALGORITHM=COPY.

mysql> ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM=COPY, LOCK=SHARED;
Query OK, 300024 rows affected (6.24 sec)
Records: 300024 Duplicates: 0 Warnings: 0

mysql> ALTER TABLE employees ADD PRIMARY KEY (emp_no), ALGORITHM=INPLACE, LOCK=NONE;
Query OK, 0 rows affected (1.48 sec)
Records: 0 Duplicates: 0 Warnings: 0 
```

<br>

다음 순서대로 `ALGORITHM`과 `LOCK` 옵션을 시도하면서 지원여부 판단  
1. `ALGORITHM=INSTANT` 옵션으로 스키마 변경 시도
2. `ALGORITHM=INPLACE, LOCK=NONE` 옵션으로 스키마 변경 시도
3. `ALGORITHM=INPLACE, LOCK=SHARED` 옵션으로 스키마 변경 시도
4. `ALGORITHM=COPY, LOCK=SHARED` 옵션으로 스키마 변경 시도
5. `ALGORITHM=COPY, LOCK=EXCLUSIVE` 옵션으로 스키마 변경 시도

<br>

### INPLACE 알고리즘












