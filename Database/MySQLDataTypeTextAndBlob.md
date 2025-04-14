# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## TEXT와 BLOB
대량의 데이터를 저장하려면 `TEXT` 또는 `BLOB` 타입을 사용, 거의 똑같은 설정이나 방식으로 작동  
`TEXT` 타입은 문자열을 저장하는 대용량 칼럼이라 문자 집합과 콜레이션을 보유  
`BLOB` 타입은 이진 데이터 타입, 내부적으로 저장 가능한 최대 길이에 따라 4가지 타입으로 구분  

| 데이터 타입 | 필요 저장 공간<br>(L = 저장하고자 하는 데이터의 바이트 수) | 저장 가능한 최대 바이트 수 |
|--|--|--|
| TINYTEXT, TINYBLOB | L + 1byte | 2^8 - 1 (255) |
| TEXT, BLOB | L + 2byte | 2^16 - 1 (65,535) |
| MEDIUMTEXT, MEDIUMBLOB | L + 3byte | 2^24 - 1 (16,777,215) |
| LONGTEXT, LONGBLOB | L + 4byte | 2^32 - 1 (4,294,967,295) |

<br>

| | 고정 길이 | 가변 길이 | 대용량 |
|--|--|--|--|
| 문자 데이터 | CHAR | VARCHAR | TEXT |
| 이진 데이터 | BINARY | VARBINARY | BLOB |

<br>

두 타입은 아래와 같은 상황에서 사용하는 것 권장
- 칼럼 하나에 저장되는 문자열 또는 이진값의 길이가 예측할 수 없이 큰 경우
- 레코드 전체 크기가 64KB 넘어서는 경우

<br>

MySQL 인덱스 레코드의 모든 칼럼은 최대 제한 크기를 보유  
`BLOB`, `TEXT` 타입의 칼럼에 인덱스를 생성할 때는 칼럼값의 몇 바이트까지 인덱스를 생성할 것인지 명시 필수  
값을 변경하는 쿼리가 문장이 매우 길어진 경우 서버로 전송되지 못하고 오류 발생 가능  
`max_allowed_packet` 시스템 변수값을 필요한 만큼 늘려서 설정  

<br>

데이터가 어떻게 저장될지 결정하는 요소는 테이블의 `ROW_FORMAT` 옵션  
별도로 지정되지 않은 경우 `innodb_default_row_format` 시스템 변수값을 적용, 기본값 dynamic  
사용 가능한 모든 포맷은 `REDUNANT`, `COMPACT`, `DYNAMIC`, `COMPRESSED`  

```
mysql> SHOW GLOBAL VARIABLES LIKE 'innodb_default_row_format';
+---------------------------+---------+
| Variable_name             | Value   |
+---------------------------+---------+
| innodb_default_row_format | dynamic |
+---------------------------+---------+
```

<br>

`COMPACT` 포맷에서 저장 가능한 레코드 하나의 최대 길이는 데이터페이지 크기의 절반인 8KB  
정확히는 8KB가 아닌 8126byte, 데이터 페이지 관리용으로 사용되는 공간을 제외한 최대 공간의 절반  

<br>

<img width="750" alt="blobandtextoffpage" src="https://github.com/user-attachments/assets/70dd963c-621f-4a2d-8d0d-bd2ae631a9d5" />

레코드 전체 길이가 8KB를 넘어선다면 용량이 큰 칼럼 순서대로 외부 페이지로 옮기면서 레코드 크기를 8KB 이하로 맞춤  
외부 페이지로 저장될 때 길이가 16KB 이상인 경우 칼럼의 값을 나눠서 여러 개의 외부 페이지에 저장하고 각 페이지는 체인으로 연결  

<br>

`COMPACT`, `REDUNANT` 레코드 포맷을 사용하는 테이블에서는 외부 페이지에 저장된 칼럼의 앞쪽 768byte만 잘라서 프라이머리 키 페이지에 같이 저장  
`DYNAMIC`, `COMPRESSED` 레코드 포맷에서는 프리픽스를 프라이머리 키 페이지에 저장하지 않음  

<br>
