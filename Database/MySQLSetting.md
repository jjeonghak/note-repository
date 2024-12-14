# 설치와 설정

## MySQL 서버의 시작과 종료

### 설정 파일 및 데이터 파일 준비  
yum 또는 rpm을 사용해서 설치한 경우 트랜잭션 로그 파일과 시스템 테이블이 준비되지 않음  
서버 설치시 `/etc/my.cnf` 경로에 기본적인 설정 파일이 생성  

<br>

```sh
mysql --defaults-file=/etc/my.cnf --initialize-insecure
```

`--initialize-insecure` 옵션은 필요한 초기 데이터 파일과 로그 파일들을 생성하고 비밀번호가 없는 관리자 계정 root 유저를 생성  
`--initialize` 옵션을 사용하면 생성된 관리자 계정의 비밀번호를 에러 로그 파일에 기록  
에러 로그 파일의 기본 경로는 `/var/log/mysqld.log` 파일  

<br>

### 시작과 종료
유닉스 계열 운영체제에서 rpm 패키지로 설치시 `/usr/lib/systemd/system/mysqld.service` 파일이 자동 생성  

```sh
systemctl start mysqld
systemctl status mysqld
systemctl stop mysqld
```

<br>

원격으로 서버를 셧다운하려면 서버에 로그인한 상태에서 `SHUTDOWN` 명령어 실행  
해당 계정은 셧다운 권한 필수  
모든 커밋된 데이터를 데이터 파일에 적용하고 종료하기 위해서 클린 셧다운 필요  

```sql
SET GLOBAL innodb_fast_shutdown=0;
SHUTDOWN;
```

<br>

### 서버 연결 테스트
```sh
mysql -uroot -p --host=localhost --socket=/tmp/mysql.sock
```

소켓 파일을 이용해서 접속 가능  
`--host=localhost` 옵션은 항상 소켓 파일을 사용해서 유닉스 프로세스 통신(IPC, inter process communication)  

<br>

```sh
mysql -uroot -p --host=127.0.0.1 --port=3306
```

TCP/IP 127.0.0.1 접속 가능  
로컬이 아닌 원격 호스트 접속시에 필수로 사용  
`--host=127.0.0.1` 옵션은 자기 서버를 가리키는 루프백(loopback) IP이기에 TCP/IP 통신  

<br>

```sh
mysql -uroot -p
```

기본값으로 호스트는 `localhost`, 소켓 파일 사용  

<br>

## MySQL 서버 업그레이드
1. 인플레이스 업그레이드(in-place upgrade)
- MySQL 서버의 데이터 파일을 그래로 두고 업그레이드  

<br>

2. 논리적 업그레이드(logical upgrade)
- mysqldump 도구 등을 이용해 MySQL 서버의 데이터를 SQL 문장이나 텍스트 파일로 덤프후 새로운 버전 서버에서 덤프된 데이터를 적재

<br>

### 인플레이스 업그레이드 제약 사항
동일 메이저 버전에서 마이너 버전 간 업그레이드의 경우 데이터 파일의 변경없이 진행  
여러 버전을 건너뛰어서 업그레이드하는 것을 허용  

메이저 버전 간 업그레이드의 경우 크고 작은 데이터 파일의 변경이 필요  
반드시 직전 버전에서만 업그레이드 허용  
메이저 버전은 직전 메이저 버전에서 사용하던 데이터 파일과 로그 포맷만 인식하도록 구현  

또한 메이저 버전 업그레이드가 특정 마이너 버전에서만 가능한 경우도 존재  
오라클에서 안정성이 확인된 `GA(general availability)` 버전에서만 가능  

<br>

## 서버 설정
일반적으로 MySQL 서버는 단 하나의 설정 파일을 사용  
리눅스와 유닉스 계열은 `my.cnf` 파일을 설정 파일로 사용  
사용하는 설정 파일은 하나지만 여러 디렉토리에 설정 파일 존재 가능  
지정된 여러 디렉토리를 순차적으로 탐색하면서 처음 발견된 설정 파일 사용  

1. `/etc/my.cnf` 파일 - 서버용
2. `/etc/mysql/my.cnf` 파일 - 서버용
3. `/usr/etc/my.cnf` 파일
4. `~/.my.cnf` 파일

<br>

```sh
mysqld --verbose --help
mysql --help
```

어느 디렉토리에 설정 파일을 읽고 있는지 확인 가능  
이미 서비스용으로 실행중인 서버에서 `mysqld` 프로그램을 시작하는 것은 권장되지 않음  
그런 경우 `mysql` 명령어로 확인  

<br>

### 설정 파일의 구성
설정 파일은 하나의 파일이나 여러 개의 설정 그룹을 담을 수 있음  
대체로 실행 프로그램 이름을 그룹명으로 사용  

```
[mysqld_safe]
malloc-lib = /opt/lib/libtcmalloc_minimal.so

[mysqld]
socket = /usr/local/mysql/tmp/mysql.sock
port = 3306

[mysql]
default-character-set = utf8mb4
socket = /usr/local/mysql/tmp/mysql.sock
port = 3304

[mysqldump]
default-character-set = utf8mb4
socket = /usr/local/mysql/tmp/mysql.sock
port = 3305
```

<br>

### MySQL 시스템 변수의 특징
서버는 가동하면서 설정 파일의 내용을 읽어 메모리나 작동 방식을 초기화  
접속된 사용자를 제어하기 위해 이러한 값을 별도로 저장  
이렇게 저장된 값이 시스템 변수(system variable)  

```sql
SHOW GLOBAL VARIABLES;
```

<br>

| Name | Cmd-Line | Option File | System Var | Var Scope | Dynamic |
|--|--|--|--|--|--|
| activate_all_roles_on_login | yes | yes | yes | global | yes |
| admin_address | yes | yes | yes | global | no |
| admin_port | yes | yes | yes | global | no |
| time_zone |  |  | yes | both | yes |
| sql_log_bin |  |  | yes | session | yes |

1. Cmd-Line - 서버의 명령행 인자로 설정 가능 여부  
2. Option File - 설정 파일 제어 가능 여부  
3. System Var - 시스템 변수 여부  
4. Var Scope - 시스템 변수 적용 범위  
5. Dynamic - 시스템 변수가 동적인지 정적인지 구분  

<br>

### 글로벌 변수와 세션 변수
글로벌 변수는 서버 인스턴스에서 전체적으로 영향을 미치는 시스템 변수  
보통 서버 자체 관련된 설정  
서버에 단 하나만 존재하는 InnoDB 버퍼 풀 크기(`innodb_buffer_pool_size`) 또는 MyISAM 키 캐시 크기(`key_buffer_size`) 등이 대표적  

세션 변수는 클라이언트가 서버에 접속할 때 기본으로 부여하는 옵션의 기본값 제어용  
기본적으로 부여받는 값이 있지만 개별 커넥션 단위로 다른 값 설정 가능  
여기서 기본값은 글로벌 시스템 변수, 각 클라이언트가 가지는 값은 세션 변수  
각 클라이언트에서 쿼리 단위로 자동 커밋을 수행할지 여부를 결정하는 `autocommit` 변수가 대표적  
한번 연결된 커넥션의 세션 변수는 서버에서 강제로 변경 불가  

세션 범위 시스템 변수 중 서버 설정 파일에 명시해 초기화할 수 있는 변수는 대부분 `Both`로 명시  
세션 변수와는 다르게 해당 값은 서버가 기억만 하다가 실제 클라이언트와 커넥션이 생성되는 순간 기본값으로 사용되는 값  

<br>

### 정적 변수와 동적 변수
서버가 가동 중인 상태에서 변경 가능한지 여부에 따라 구분  
디스크에 저장돼 있는 값을 변경하는 경우와 인메모리에 있는 값을 변경하는 경우로 구분 가능  

`SET` 명령을 통해 변경되는 시스템 변수값은 설정 파일에 반영되는 것이 아닌 가동 중인 인스턴스에서만 유효  
8.0 버전 이후 `SET PERSIST` 명령을 통해 영구적 반영 가능, 해당 변경 사항은 설정 파일이 아닌 별도의 파일에 기록  

```
mysql> SHOW GLOBAL VARIABLES LIKE 'max_connections';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 1000  |
+-----------------+-------+

mysql> SET PERSIST_ONLY max_connections=5000;
mysql> SHOW GLOBAL VARIABLES LIKE 'max_connections';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 5000  |
+-----------------+-------+
```

<br>

`SET PERSIST_ONLY` 명령은 현재 서버에는 적용하지 않고 다음 재시작때 변수값을 영구적으로 변경할 때 사용  
동적인 변수값을 변경함과 동시에 정적인 변수도 다음 재실행때 반영될 수 있도록 미리 변경 가능  

```
mysql> SET PERSIST_ONLY max_connections=5000;
mysql> SHOW GLOBAL VARIABLES LIKE 'max_connections';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 1000  |
+-----------------+-------+

mysql> SET PERSIST innodb_doublewrite=ON;
ERROR 1238 (HY000): Variable 'innodb_doublewrite' is a read only variable

mysql> SET PERSIST_ONLY innodb_doublewrite=ON;
Query OK, 0 raws affected (0.00 sec)
```

해당 명령으로 변경된 사항은 `mysqld-auto.cnf` 파일에 기록  

```json
{
  "Version": 1,
  "mysql_server": {
    "max_connections": {
      "Value": "5000",
      "Metadata": {
        "Timestamp": 1603531428710224,
        "User": "matt.lee",
        "Host": "localhost"
      }
    },
    "mysql_server_static_options": {
      "innodb_doublewrite": {
        "Value": "ON",
        "Metadata": {
          "Timestamp": 1603531680005055,
          "User": "matt.lee",
          "Host": "localhost"
        }
      }
    }
  }
}
```

변경된 시스템 변수의 메타데이터는 `performace_schema.variables_info` 뷰와 `performace_schema.persisted_variables` 테이블을 통해 참조 가능  

```
mysql> SELECT a.variable_name, b.variable_value, a.set_time, a.set_user, a.set_host
        FROM performace_schema.variables_info a
        INNER JOIN performace_schema.persisted_variables b
        ON a.variable_name=b.variable_name
        WHERE b.variable_name LIKE 'max_connections'\G
*************************** 1. row ***************************
 VARIABLE_NAME: max_connections
VARIABLE_value: 5000
      SET_TIME: 2020-10-24 18:23:48.710605
      SET_USER: matt.lee
      SET_HOST: localhost
```

<br>

위의 명령으로 추가된 시스템 변수 내용을 삭제하고 싶은 경우 `RESET PERSIST` 명령 사용  
`mysqld-auto.cnf` 파일을 직접 수정하는 것은 권장되지 않음  

```sql
## 특정 시스템 변수만 삭제
REST PERSIST max_connections;
REST PERSIST IF EXISTS max_connections;

## mysqld-auto.cnf 파일에 기록된 모든 변수 삭제
REST PERSIST;
```

<br>

### my.cnf 파일
8.0 버전 기준 서버 시스템 변수는 대략 570개  

```
[mysqld]
server-id=1
user=mysql
...

### InnoDB
innodb_sort_buffer_size=64M
...

### Performance schema
performance_schema=ON
...

#### TDE (Encryption)
early-plugin-load=keyring_file.so
...

#### Password validate
password_history=5
...

#### MySQL BinLog
log-bin=/log/mysql-bin/mysql-bon
...

#### MySQL Replica Options
slave_parallel_type=LOGICAL_CLOCK
...

#### Relay Log
relay-log=/log/relay-bin/relay-bin
...

#### MySQL ErrorLog
log-error=/log/mysql-err.log
...

#### MySQL Slow Log
slow-query-log=1
...

#### MySQL Log Expire
binlog_expire_logs_seconds=259200
...
```

<br>
