# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## 문자열(CHAR와 VARCHAR)
문자열 칼럼을 사용할 때는 `CHAR` 타입과 `VARCHAR` 타입 중 선택  

<br>

### 저장 공간
가장 큰 차이는 고정 길이냐 가변 길이냐의 차이  
- 고정 길이는 실제 입력되는 칼럼값의 길이에 따라 저장 공간 크기 변화 없음  
`CHAR` 타입은 이미 저장 공간의 크기가 고정적  
실제 저장된 값의 유효 크기가 얼마인지 별도로 저장할 필요 없으므로 추가 공간 필요 없음  

- 가변 길이는 최대로 저장할 수 있는 값의 길이는 제한, 그 이하 크기의 값이 저장되면 그만큼 저장 공간 변화  
`VARCHAR` 타입은 저장된 값의 유효 크기가 얼마인지 1 ~ 2 byte 별도로 저장 필요  

<br>

MySQL에서는 하나의 레코드에서 `TEXT`, `BLOB` 타입을 제외한 칼럼의 전체 크기가 `64KB` 초과 불가  
만약 `VARCHAR` 타입을 사용해서 크기를 초과한 경우 에러 발생 혹은 `TEXT` 타입으로 대체  

<br>

<img width="300" alt="varcharmemory" src="https://github.com/user-attachments/assets/23ca5092-5618-49d6-bb4d-aaa256a84bd6" />

<br>

<img width="400" alt="charmemory" src="https://github.com/user-attachments/assets/a268f5f3-f866-418b-8f6c-5a1bd0754d15" />

문자열 값의 길이가 항상 일정하다면 `CHAR`를 사용하고 가변적이라면 `VARCHAR` 사용하는 것이 일반적  
- 저장되는 문자열의 길이가 대개 비슷한가?
- 칼럼의 값이 자주 변경되는가?

<br>

만약 길이가 5인 문자열로 변경된다면
- `VARCHAR(10)`: 레코드 자체를 다른 공간으로 옮겨서(`Row migration`) 저장  
- `CHAR(10)`: 그냥 변경되는 칼럼의 값을 업데이트  

<br>

두 타입으로 칼럼을 정의할때 지정하는 숫자는 그 칼럼의 바이트 크기가 아닌 문자의 수를 의미  
- 일반적으로 영어를 포함한 서구권 언어는 각 문자가 1byte 사용
- 한국어나 일본어 같은 아시아권 언어는 각 문자가 최대 2byte 사용
- 유니코드는 최대 4byte 사용

<br>

### 저장 공간과 스키마 변경(Online DDL)
데이터가 변경되는 도중에 스키마 변경을 할수 있도록 지원하는 기능  
`VARCHAR` 타입을 사용하는 칼럼의 길이를 늘리는 작업은 길이에 따라 성능과 잠금 차이 발생  

<br>

```
mysql> CREATE TABLE test (
         id INT PRIMARY KEY,
         value VARCHAR(60)
       ) DEFAULT CHARSET=utf8mb4;

mysql> ALTER TABLE test MODIFY value VARCHAR(63), ALGORITHM=INPLACE, LOCK=NONE;
Query OK, 0 rows affected (0.00 sec)

mysql> ALTER TABLE test MODIFY value VARCHAR(64) ALGORITHM=INPLACE, LOCK=NONE;
ERROR 1846 (0A000): ALGORITHM=INPLACE is not supported. Reason: Cannot change column type
INPLACE. Try ALGORITHM=COPY.

mysql> ALTER TABLE test MODIFY value VARCHAR(64), ALGORITHM=COPY, LOCK=SHARED;
Query OK, 1000000 rows affected (36.12 sec)
```

`VARCHAR(60)` 칼럼의 최대 길이는 240(60 * 4)byte이기 때문에 문자열의 길이를 저장하는 공간은 1byte  
`VARCHAR(64)` 칼럼의 최대 길이는 256(64 * 4)byte이기 때문에 문자열의 길이를 저장하는 공간은 2byte  

<br>

## 문자 집합(캐릭터 셋)
각 테이블의 칼럼은 모두 서로 다른 문자 집합을 사용해 문자열 저장 가능  
최종적으로 칼럼 단위로 문자 집합 관리하지만 편의를 위해 데이터베이스, 테이블 단위로 설정 기능 제공  
한글 기반의 서비스에서는 `euckr` 또는 `utf8mb4`, 일본어는 `cp932` 또는 `utf8mb4` 문자 집합을 사용  
최근 웹 서비스는 국제화를 위해 `utf8mb4` 문자 집합을 사용하는 추세  

```
mysql> SHOW CHARACTER SET;
+---------+---------------------------+---------------------+--------+
| Charset | Description               | Default collation   | Maxlen |
+---------+---------------------------+---------------------+--------+
| ascii   | US ASCII                  | ascii_general_ci    |      1 |
| binary  | Binary pseudo charset     | binary              |      1 |
| cp932   | SJIS for Windows Japanese | cp932_japanese_ci   |      2 |
| eucjpms | UJIS for Windows Japanese | eucjpms_japanese_ci |      3 |
| euckr   | EUC-KR Korean             | euckr_korean_ci     |      2 |
| latin1  | cp1252 West European      | latin1_swedish_ci   |      1 |
| utf8    | UTF-8 Unicode             | utf8_general_ci     |      3 |
| utf8mb4 | UTF-8 Unicode             | utf8_general_ci     |      4 |
| ...     | ...                       | ...                 |    ... |
+---------+---------------------------+---------------------+--------+
```

<br>

<img width="700" alt="characterset" src="https://github.com/user-attachments/assets/a90b6b17-ebce-4ae1-afa3-20eb89233990" />

문자 집합을 설정하는 시스템 변수에 따라 목적이 상이
- `character_set_system`  
MySQL 서버가 식별자를 저장할 때 사용하는 문자 집합  
이 값은 기본적으로 `utf8`로 설정되며 사용자가 변경할 필요 없음  

- `character_set_server`  
서버 기본 문자 집합으로 아무런 문자 집합이 설정되지 않을때 해당 문자 집합 사용  

- `character_set_database`  
데이터베이스 기본 문자 집합으로 아무런 문자 집합이 설정되지 않을때 해당 문자 집합 사용  

- `character_set_filesystem`  
`LOAD DATA INFILE ...` 또는 `SELECT ... INTO OUTFILE` 파일의 이름을 해석할때 사용되는 문자 집합  
파일 내용을 읽을때 사용하는 문자 집합이 아닌 파일의 이름을 찾을때 사용하는 문자 집합  
해당 시스템 변수의 기본값은 `utf8mb4`  

- `character_set_client`  
클라이언트가 보낸 SQL 문장을 서버에 보낼때 인코딩하는 문자 집합  
이 값은 커넥션에서 임의의 문자 집합으로 변경해서 사용 가능  

- `character_set_connection`  
서버가 클라이언트로부터 전달받은 SQL 문장을 처리하기 위해 사용하는 문자 집합  

- `character_set_results`  
서버가 쿼리 처리 결과를 클라이언트로 보낼때 사용하는 문자 집합
해당 시스템 변수의 기본값은 `utf8mb4`  

<br>

### 클라이언트로부터 쿼리를 요청했을 때의 문자 집합 변환
SQL 문장에서 별도로 문자 집합을 설정하는 지정자를 인트로듀서라고 칭함  
인트로듀서가 없는 경우 `character_set_connection` 시스템 변수값의 문자 집합으로 처리  
일반적으로 인트로듀서는 `_utf8mb4` 또는 `_latin1` 같이 언더스코어 기호와 문자 집합의 이름을 붙여서 표현  

```sql
SELECT emp_no, first_name FROM employees WHERE first_name = 'Matt';
SELECT emp_no, first_name FROM employees WHERE first_name = _latin1'Matt';
```

<br>

### 처리 결과를 클라이언트로 전송할 때의 문자 집합 변환
전체 과정에서 변환 전의 문자 집합과 변환해야할 문자 집합이 같다면 별도의 문자 집합 변환 작업은 모두 생략  
`character_set_cilent`, `character_set_results`, `character_set_connection` 시스템 변수는 클라이언트가 변경 가능  
이 시스템 변수는 모두 세션 변수이면서 동적 변수  

```sql
SET character_set_client = 'utf8mb4';
SET character_set_results = 'utf8mb4';
SET character_set_connection = 'utf8mb4';

SET NAMES utf8mb4;
CHARSET utf8mb4;
```

<br>

## 콜레이션(Collation)
콜레이션은 문자열 칼럼값에 대한 비교나 정렬 순서를 위한 규칙을 의미  
모든 문자열 타입의 칼럼은 독립적인 문자 집합과 콜레이션을 보유  

<br>

### 콜레이션 이해
문자 집합은 2개 이상의 콜레이션을 보유, 하나의 문자 집합에 속한 콜레이션은 다른 문자 집합과 공유해서 사용 불가  
문자 집합만 지정한 경우 해당 문자 집합의 기본 콜레이션이 지정, 반대의 경우 해당 콜레이션이 소속된 문자 집합이 묵시적응로 지정  

<br>

```
mysql> SHOW COLLATION;
+
| Collation         | Charset | Id | Default | Compiled | Sortlen | Pad_attribute |
+
| ascii_bin         | ascii   | 65 |         |      Yes |       1 |     PAD SPACE |
| ascii_general_ci  | ascii   | 11 |     Yes |      Yes |       1 |     PAD SPACE |
| euckr_bin         | euckr   | 85 |         |      Yes |       1 |     PAD SPACE |
| euckr_korean_ci   | euckr   | 19 |     Yes |      Yes |       1 |     PAD SPACE |
| latin1_bin        | latin1  | 47 |         |      Yes |       1 |     PAD SPACE |
| latin1_general_ci | latin1  | 48 |         |      Yes |       1 |     PAD SPACE |
| latin1_general_cs | latin1  | 49 |         |      Yes |       1 |     PAD SPACE |
| ...               | ...     | .. |     ... |      ... |     ... |           ... |
```

- 3개 파트로 구성된 콜레이션 이름  
첫번째 파트는 문자 집합의 이름  
두번째 파트는 해당 문자 집합의 하위 분류  
세번째 파트는 대문자나 소문자의 구분 여부(`ci`, `cs`)  

- 2개 파트로 구성된 콜레이션 이름  
첫번째 파트는 문자 집합의 이름  
두번째 파트는 항상 `bin` 키워드 사용  
이진 데이터로 관리되는 문자열 칼럼은 별도의 콜레이션을 가지지 않음  

<br>


