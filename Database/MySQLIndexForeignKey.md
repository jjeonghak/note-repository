# 인덱스
인덱스 특성과 치이는 물리 수준 모델링에 중요한 요소  
기존 MyISAM 스토리지 엔진에서만 제공하던 전문 검색, 위치 기반 검색 기능도 지원  
쿼리 튜닝의 기본  

<br>

## 외래키
InnoDB 스토리지 엔진에서만 외래키 생성 가능  
외래키 제약이 설정된 경우 자동으로 연관된 테이블의 칼럼에 인덱스 생성  
- 테이블의 변경이 발생한 경우에만 잠금 경합 발생  
- 외래키와 연관되지 않은 칼럼의 변경은 최대한 잠금 경합을 발생시키지 않음  

```
mysql> CREATE TABLE tb_parent (
         id INT NOT NULL,
         fd VARCHAR(100) NOT NULL,
         PRIMARY KEY (id)
       ) ENGINE=InnoDB;

mysql> CREATE TABLE tb_child (
         id INT NOT NULL,
         pid INT DEFAULT NULL,
         fd VARCHAR(100) DEFAULT NULL,
         PRIMARY KEY (id),
         KEY ix_parentid (pid),
         CONSTRAINT child_ibfk_1 FOREIGN KEY (pid) REFERENCES tb_parent (id) ON DELETE CASCADE
       ) ENGINE=InnoDB;

mysql> INSERT INTO tb_parent VALUES (1, 'parent-1'), (2, 'parent-2');
mysql> INSERT INTO tb_child VALUES (100, 1, 'child-100');
```

<br>

### 자식 테이블의 변경이 대기하는 경우
| 작업 번호 | 커넥션-1 | 커넥션-2 |
|--|--|--|
| 1 | BEGIN; | |
| 2 | UPDATE tb_parent <br> SET fd = 'changed-2' WHERE id = 2; | |
| 3 | | BEGIN; |
| 4 | | UPDATE tb_child <br> SET pid = 2 WHERE id = 100; |
| 5 | ROLLBACK; | |
| 6 | | Query OK, 1 row affected (3.04 sec) |


자식 테이블의 외래키 칼럼의 변경은 부모 테이블의 확인 필수  
부모 테이블의 해당 레코드가 쓰기 잠금이 걸려 있으면 해당 쓰기 잠금이 해제될 때까지 대기  
자식 테이블의 외래키가 아닌 칼럼의 변경은 외래키로 인한 잠금 확장이 발생하지 않음  

<br>


### 부모 테이블의 변경 작업이 대기하는 경우
| 작업 번호 | 커넥션-1 | 커넥션-2 |
|--|--|--|
| 1 | BEGIN; | |
| 2 | UPDATE tb_child <br> SET fd = 'changed-100' WHERE id = 100; | |
| 3 | | BEGIN; |
| 4 | | DELETE FROM tb_parent <br> WHERE id = 1; |
| 5 | ROLLBACK; | |
| 6 | | Query OK, 1 row affected (6.09 sec) |

외래키 특성(`ON DELETE CASCADE`)으로 인해 부모 테이블의 레코드를 삭제할 때 연관된 자식 테이블 레코드 확인 필수  

<br>
