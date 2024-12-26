# 인덱스
인덱스 특성과 치이는 물리 수준 모델링에 중요한 요소  
기존 MyISAM 스토리지 엔진에서만 제공하던 전문 검색, 위치 기반 검색 기능도 지원  
쿼리 튜닝의 기본  

<br>

## 전문 검색 인덱스
B-Tree 인덱스는 전체 일치 또는 좌측 일부 일치와 같은 검색만 가능  
문서의 내용 전체를 인덱스화해서 특정 키워드가 포함된 문서를 검색하는 전문 검색에는 B-Tree 사용 불가  

<br>

### 인덱스 알고리즘
전문 검색에서는 문서 본문의 내용에 키워드를 분석한 후 빠른 검색용으로 인덱스를 구축  
인덱싱하는 기법에 따라 `어근 분석`과 `n-gram` 분석 알고리즘으로 분석 가능

<br>

### 어근 분석 알고리즘
전문 검색 인덱스는 불용어 처리(`Stop Word`)와 어근 분석(`Stemming`) 과정을 거쳐서 색인 작업 수행  
불용어 처리는 검색에서 가치가 없는 단어를 모두 필터링  
기본적으로 불용어 소스코드를 제공하지만 사용자가 별도로 불용어 정의 가능  

어근 분석은 검색어 단어의 뿌리인 원형을 찾는 작업  
오픈 소스 형태소 분석 라이브러리인 `MeCab` 플러그인을 지원  
한글이나 일본어의 경우 단어의 변형보단 문장의 형태소를 분석해서 명사와 조사 구분이 중요  
제대로 동작하기 위해서는 단어 사전과 단어의 품사를 식별할 수 있는 문장 구조 인식이 필수  
적용하는 방법은 어렵지 않지만 한글에 맞는 완성도를 갖추는 작업에 많은 시간이 필요  

<br>

### n-gram 알고리즘
`MeCab` 형태소 분석은 만족할 만한 결과를 내기위해 많은 시간이 필요  
전문적인 검색 엔진을 고려하는 것이 아니라면 범용적으로 적용하기 쉽지 않음  
`n-gram` 알고리즘은 단순히 키워드를 검색해내기 위한 인덱싱 알고리즘  

본문을 무조건 몇 글자씩 잘라서 인덱싱하는 방법  
형태소 분석보다 알고리즘이 단순하고 국가별 언어 이해와 준비 작업이 필요 없음  
하지만 만들어지는 인덱스의 크기가 상당히 큰 편  
n은 인덱싱할 키워드의 최소 글자 수를 의미, 일반적으로 `2-gram` 방식을 많이 사용  

<br>

<img width="500" alt="bigram" src="https://github.com/user-attachments/assets/b8f4641e-822f-42b5-89ff-324aaf982440" />

생성된 토큰들에 대해 불용어를 걸러내는 작업도 수행  
불용어와 동일하거나 포함한 경우 필터링  

```
mysql> SELECT * FROM information_scheam.INNODB_FT_DEFAULT_STOPWORD;
+-------+
| value |
+-------+
| a     |
| about |
| an    |
| ...   |
+-------+
36 rows in set (0.00 sec)
```

<br>

### 불용어 변경 및 삭제
기본 불용어 처리는 사용자를 더 혼란스럽게 하는 기능일 가능성 존재  
내장된 불용어 대신 사용자 정의 불용어 사용을 권장  

<br>

### 전문 검색 인덱스의 불용어 처리 무시
스토리지 엔진에 관계없이 모든 전문 검색 인덱스에 대해 불용어 완전히 제거 가능
설정 파일의 `ft_stopword_file` 시스템 변수값을 빈 문자열로 설정  
내장 불용어를 비활성화할 수도 있지만 사용자 정의 불용어를 적용할 때도 사용  
해당 시스템 변수값에 사용자 정의 불용어 파일 경로를 입력  

InnoDB 스토리지 엔진을 사용하는 테이블의 전문 검색 인덱스에 대해서만 불용어 처리 무시 가능  
`innodb_ft_enable_stopword` 시스템 변수값을 OFF 설정  
동적인 시스템 변수이기에 실행중에 변경 가능  

<br>

### 사용자 정의 불용어 사용
불용어 목록을 파일로 저장하고 `ft_stopword_file` 시스템 변수값에 경로 설정  
InnoDB 스토리지 엔진을 사용하는 테이블의 전문 검색 엔진에서는 불용어를 테이블로 저장하는 방식  
불용어 테이블을 생성하고 `innodb_ft_server_stopword_table` 시스템 변수값에 설정  
만약 여러 전문 검색 인덱스가 서로 다른 불용어를 사용해야한다면 `innodb_ft_user_stopword_table` 시스템 변수를 사용  

```sql
CREATE TABLE my_stopword(value VARCHAR(30)) ENGINE = INNODB;
INSERT INTO my_stopword(value) VALUES('MySQL');
SET GLOBAL innodb_ft_server_stopword_table='mydb/my_stopword';
ALTER TABLE tb_bi_gram ADD FULLTEXT INDEX fx_title_body(title, body) WITH PARSER ngram;
```

<br>

### 전문 검색 인덱스의 가용성
반드시 아래 두가지 조건을 갖춰야함  
- 쿼리 문장이 전문 검색을 위한 문법(`MATCH ... AGAINST ...`)
- 테이블이 전문 검색 대상 칼럼에 대해서 전문 인덱스 보유

<br>

```sql
CREATE TABLE tb_test(
  doc_id INT,
  doc_body TEXT,
  PRIMARY KEY (doc_id),
  FULLTEXT KEY fx_docbody (doc_body) WITH PARSER ngram
) ENGINE=InnoDB;

SELECT * FROM tb_test WHERE doc_body LIKE '%apple%';
```

해당 쿼리는 전문 검색 인덱스를 이용하지 않고 풀 테이블 스캔으로 쿼리 처리  
전문 검색 인덱스를 사용하려면 반드시 `MATCH ... AGAINST ...` 구문 검색 필수  

```sql
SELECT * FROM tb_test WHERE MATCH(doc_body) AGAINST('apple' IN BOOLEAN MODE);
```

<br>
