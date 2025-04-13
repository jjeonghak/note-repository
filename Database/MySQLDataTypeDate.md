# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## 날짜와 시간
날짜만 저장하거나 시간만 따로, 또는 함께 저장 가능  

| 데이터 타입 | 5.6.4 이전 | 5.6.4 이후 |
|--|--|--|
| YEAR | 1byte | 1byte |
| DATE | 3byte | 3byte |
| TIME | 3btye | 3byte + (밀리초 단위 저장 공간) |
| DATETIME | 8byte | 5byte + (밀리초 단위 저장 공간) |
| TIMESTAMP | 4byte | 4byte + (밀리초 단위 저장 공간) |

<br>

밀리초 단위는 2자당 1byte 공간이 더 필요  

| 밀리초 단위 자리수 | 저장 공간 |
|--|--|
| 없음 | 0byte |
| 1, 2 | 1byte |
| 3, 4 | 2byte |
| 5, 6 | 3byte |

<br>

밀리초 단위로 데이터를 저장하기 위해서는 괄호와 함께 숫자를 표기  
표기하지 않은 경우 자동으로 (0)으로 실행되어 밀리초 단위는 0으로 반환  

```
mysql> CREATE TABLE tb_datetime (current DATETIME(6));
mysql> INSERT INTO tb_datetime VALUES (NOW());
mysql> SELECT * FROM tb_datetime;
+----------------------------+
| current                    |
+----------------------------+
| 2020-09-09 21:32:58.000000 |
+----------------------------+

mysql> INSERT INTO tb_datetime VALUES (NOW(6));
mysql> SELECT * FROM tb_datetime;
+----------------------------+
| current                    |
+----------------------------+
| 2020-09-09 21:32:58.000000 |
| 2020-09-09 21:33:07.574356 |
+----------------------------+
```

<br>

MySQL의 날짜 타입은 칼럼 자체에 타임존 정보가 저장되지 않음  
`DATETIME`, `DATE` 타입은 클라이언트로부터 입력된 값을 그대로 저장하고 조회  
하지만 `TIMESTAMP` 타입은 항상 UTF 타임존으로 저장되므로 자동 보정  

```
mysql> CREATE TABLE tb_timezone (fd_datetime DATETIME, fd_timestamp TIMESTAMP);
mysql> SET time_zone = 'Asia/Seoul'; /* '+09:00' */
mysql> INSERT INTO tb_timezone VALUES (NOW(), NOW());

mysql> SELECT * FROM tb_timezone;
+---------------------+---------------------+
| fd_datetime         | fd_timestamp        |
+---------------------+---------------------+
| 2020-09-10 09:25:23 | 2020-09-10 09:25:23 |
+---------------------+---------------------+

mysql> SET time_zone = 'America/Los_Angeles'; /* -07:00 */
mysql> SELECT * FROM tb_timezone;
+---------------------+---------------------+
| fd_datetime         | fd_timestamp        |
+---------------------+---------------------+
| 2020-09-10 09:25:23 | 2020-09-09 17:25:23 |
+---------------------+---------------------+
```

<br>

만약 타임존 정보가 MySQL 서버에 준비되지 않은 경우 오류 발생  
타임존 정보를 적재하기 어려운 경우 대안으로 시간 차이로 설정 가능  

```
mysql> SET time_zone = 'Asia/Seoul'; /* +09:00 */
ERROR 1298 (HY000): Unknown or incorrect time zone: 'Asia/Seoul'

mysql> SET time_zone = '+09:00'; /* Asia/Seoul' */
```

<br>

자바 응용 프로그램의 타임존을 설정한 경우 날짜 및 시간 정보를 JVM 타임존으로 변환해서 출력  
JDBC 연결 문자열은 자바 응용 프로그램이 아니라 MySQL 서버의 타임존을 지정하는 것  

```java
// JVM 타임존을 서울로 변경
System.setProperty("user.timezone", "Asia/Seoul");
Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306?serverTimezone=Asia/Seoul", "id", "pass");
Statement stmt = Conn.createStatement();
ResultSet res = stmt.executeQuery("SELECT fd_datetime, fd_timestamp FROM test.tb_timezone");

if (res.next()) {
  // fd_datetime : 2020-09-10 09:25:23.0
  System.out.println("fd_datetime : " + tes.getTimestamp("fd_datetime"));
  // fd_timestamp : 2020-09-10 09:25:23.0
  System.out.println("fd_timestamp : " + tes.getTimestamp("fd_timestamp"));
}

// JVM 타임존을 로스앤젤레스로 변경
System.setProperty("user.timezone", "America/Los_Angeles");
Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306?serverTimezone=Asia/Seoul", "id", "pass");
Statement stmt = Conn.createStatement();
ResultSet res = stmt.executeQuery("SELECT fd_datetime, fd_timestamp FROM test.tb_timezone");

if (res.next()) {
  // fd_datetime : 2020-09-09 17:25:23.0
  System.out.println("fd_datetime : " + tes.getTimestamp("fd_datetime"));
  // fd_timestamp : 2020-09-09 17:25:23.0
  System.out.println("fd_timestamp : " + tes.getTimestamp("fd_timestamp"));
}
```

<br>

이미 데이터를 가지고 있는 서버의 타임존을 변경하는 경우 타임존 설정뿐만 아니라 `DATETIME` 칼럼이 가지고 있는 값도 `CONVERT_TZ()` 변환 필수  
하지만 `TIMESTAMP` 타입의 값은 서버 타임존에 의존적이지 않고 항상 UTC로 저장되므로 별도의 변환 작업 필요 없음  
`system_time_zone` 시스템 변수는 서버의 타임존을, `time_zone` 시스템 변수는 커넥션 기본 타임존을 의미  

```
mysql> SET time_zone='America/Los_Angeles';
mysql> SHOW VARIABLES LIKE '%time_zone%';
+------------------+---------------------+
| Variable_name    | Value               |
+------------------+---------------------+
| system_time_zone | KST                 |
| time_zone        | America/Los_Angeles |
+------------------+---------------------+
```

<br>

### 자동 업데이트
5.6 이전 버전까지는 `TIMESTAMP` 타입의 칼럼은 다른 칼럼 데이터가 변경될 때마다 시간이 자동 업데이트되고, `DATETIME`은 그렇지 않음  
5.6 버전부터 두 타입 모두 INSERT, UPDAATE 문장이 실행될 때마다 해당 시점으로 자동 업데이트되게 하려면 옵션 필요  

```sql
CREATE TABLE tb_autoupdate (
  id BIGINT NOT NULL AUTO_INCREMENT,
  title VARCHAR(20),
  created_at_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_ts TIMESTAMP DEFAULT ON UPDATE CURRENT_TIMESTAMP,
  created_at_dt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at_dt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);
```

<br>
