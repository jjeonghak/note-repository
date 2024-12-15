# 사용자 및 권한

다른 DBMS와는 계정 관리 방식에 차이가 존재  
사용자의 아이디뿐 아니라 해당 사용자가 어느 IP에서 접속하는지도 확인  
권한을 묶어서 관리하는 역할 개념도 도입  

<br>

## 사용자 식별
사용자의 접속 지점도 계정의 일부  
따라서 항상 아이디와 호스트를 함께 명시  

```
'svc_id'@'127.0.0.1'
```

<br>

동일한 아이디가 있을때 해당 사용자의 인증을 하는 방식 상이  
항상 범위가 가장 작은 것을 먼저 선택해서 적용  

```
'svc_id'@'192.168.0.10' (이 계정의 비밀번호는 123)
'svc_id'@'%' (이 계정의 비밀번호는 abc)
```

<br>

## 사용자 계정 관리

### 시스템 계정과 일반 계정
8.0 버전부터 `SYSTEM_USER` 권한 여부에 따라 시스템 계정과 일반 계정으로 구분  
시스템 계정은 서버 관리자를 위한 계정, 일반 계정은 응용 프로그램이나 개발자를 위한 계정  

시스템 계정은 서버 관련 중요 작업 가능  
- 계정 관리(계정 생성 및 삭제, 계정의 권한 부여 및 제거)
- 다른 세션(connection) 또는 해당 세션의 실행중인 쿼리를 강제 종료
- 스토어드 프로그램 생성시 DEFINER를 타 사용자로 설정

<br>

`root` 계정 외에도 기본적으로 내장된 계정은 내부적으로 각기 다른 목적으로 사용되므로 삭제되지 않도록 주의  
- `'mysql.sys'@'localhost'`: sys 스키마 객체들의 DEFINER로 사용되는 계정
- `'mysql.session'@'localhost'`: 플러그인이 서버로 접근할때 사용되는 계정
- `'mysql.infoschema'@'localhost'`: information_schema에 정의된 뷰의 DEFINER로 사용되는 계정

<br>

위의 언근한 3개의 계정은 처음부터 잠겨 있는 상태(`account_locked` 칼럼)  
의도적으로 풀지않는 이상 보안 걱정 없음  

```
mysql> SELECT user, host, accoumt_locked FROM mysql.user WHERE user LIKE 'mysql.%';
+------------------+-----------+----------------+
| user             | host      | account_locked |
+------------------+-----------+----------------+
| mysql.infoschema | localhost | Y              |
| mysql.session    | localhost | Y              |
| mysql.sys        | localhost | Y              |
+------------------+-----------+----------------+
```

<br>

### 계정 생성
5.7 버저까지는 `GRANT` 명령으로 권한 부여 및 생성이 가능  
8.0 버전부터는 계정 생성은 `CREATE USER`, 권한 부여는 `GRANT` 명령으로 구분  

```
mysql> CREATE USER 'user'@'%'
        IDENTIFIED WITH 'mysql_native_password' BY 'password'
        REQUIRE NONE
        PASSWORD EXPIRE INTERVAL 30 DAY
        ACCOUNT UNLOCK
        PASSWORD HOSTORY DEFAULT
        PASSWORD REUSE INTERVAL DEFAULT
        PASSWORD REQUIRE CURRENT DEFAULT; 
```

### IDENTIFIED WITH
사용자 인증 방식과 비밀번호 설정  
반드시 인증 방식(인증 플러그인 이름)을 명시  
기본 인증 방식은 `IDENTIFIED WITH 'password'`  

다양한 인증 플러그인 존재  
1. **Native Pluggable Authentication**  
  5.7 버전까지 기본으로 사용되던 방식  
  비밀번호에 대한 해시(SHA-1) 값을 저장후 비교  

2. **Caching SHA-2 Pluggable Authentication**  
  8.0 버전부터 기본으로 사용되는 방식  
  SHA-2 알고리즘을 사용해서 동일 입력값에 대해 다른 해시값 출력  
  SCRAM(salted challenge response authentication mechanism) 인증 방식 사용  
  평문 비밀번호를 이용해서 5000번 이상 암호화 해시 함수를 실행해야 서버로 로그인 요청 가능  
  해당 값은 `caching_sha2_password_digest_rounds` 시스템 변수로 설정 가능(기본값 5000, 최소 설정 가능값 5000)  
  성능이 매우 떨어지는 단점을 보완하기 위해서 결과 해시값을 메모리 캐시에 저장해서 사용  

4. **PAM Pluggable Authentication**  
  엔터프라이즈 에디션에서만 사용 가능  
  유닉스나 리눅스 패스워드 또는 LDAP(lightweight directory access protocol) 같은 외부 인증 사용을 위한 방식  

5. **LDAP Pluggable Authentication**  
  엔터프라이즈 에디션에서만 사용 가능  
  LDAP 같은 외부 인증 사용을 위한 방식  

<br>

서버의 기본 인증 방식을 변경하기 위해서는 `my.cnf` 설정 파일을 수정  

```
SET GLOBAL default_authentication_plugin="mysql_native_password"
```

<br>

### REQUIRE
서버 접속시 SSL/TLS 채널 사용 여부 설정  
설정하지 않는 경우 비암호화 채널로 연결  

<br>

### PASSWORD EXPIRE
비밀번호 유효 기간 설정  
별도로 명시하지 않는 경우 `default_password_lifetime` 시스템 변수값으로 설정  
개발자가 직접 기간을 설정하는 것은 안전하지만, 응용프로그램 접속용 계정이 설정하는 것은 위험  

- PASSWROD EXPIRE: 계정 생성과 동시에 비밀번호 만료  
- PASSWROD EXPIRE NEVER: 계정 비밀번호 만료기간 없음  
- PASSWROD EXPIRE DEFAULT: 시스템 변수값으로 설정  
- PASSWROD EXPIRE INTERVAL n DAY: 오늘부터 n일자로 설정  

<br>

### PASSWORD HISTORY
한번 사용했던 비밀번호의 재사용 가능 여부 설정  
`password_history` 시스템 변수값만큼 비밀번호 이력을 저장  

- PASSWORD HISTORY DEFAULT: 저장된 이력에 있는 비밀번호 재사용 금지  
- PASSWORD HISTORY n: 비밀번호 이력을 최근 n개까지만 저장하고 재사용 금지  

```
mysql> SELECT * FROM mysql.password_history;
+-----------+------+----------------------------+-------------+
| Host      | User | Password_timestamp         | Password    |
+-----------+------+----------------------------+-------------+
| localhost | root | 2020-07-15 11:42:23.987696 | *AA1420F... |
+-----------+------+----------------------------+-------------+
```

<br>

### PASSWORD REUSE INTERVAL
한번 사용했던 비밀번호 재사용 금지 기간 설정  
별도로 명시하지 않는 경우 `password_reuse_interval` 시스템 변수값으로 설정  

- PASSWORD REUSE INTERVAL DEFAULT: 기본 시스템 변수값으로 설정  
- PASSWORD REUSE INTERVAL n DAY: n일자 이후로 설정  

<br>

### PASSWORD REQUIRE
비밀번호 만료후 새로운 비밀번호로 변경할때 현재 비밀번호를 필요로 할지 설정  
별도로 명시하지 않는 경우 `password_require_current` 시스템 변수값으로 설정  

- PASSWORD REQUIRE CURRENT: 비밀번호를 변경할때 현재 비밀번호를 먼저 입력하도록 설정  
- PASSWORD REQUIRE OPTIONAL: 비밀번호를 변경할때 현재 비밀번호를 입력하지 않아도 되도록 설정  
- PASSWORD REQUIRE DEFAULT: 기본 시스템 변수값으로 설정  

<br>

### ACCOUNT LOCK / UNLOCK
계정 생성시 또는 `ALTER USER` 명령으로 계정 정보를 변경할때 계정을 사용하지 못하게 잠금 여부 설정  

<br>

## 비밀번호 관리

### 고수준 비밀번호
비밀번호 글자 조합을 강제하거나 금칙어를 설정 가능  
유효성 체크 규칙을 적용하려면 `validate_password` 컴포넌트 설치 필수  
서버 프로그램에 내장돼 있기 때문에 별도의 파일 경로 지정하지 않아도 사용 가능  

```
mysql> INSTALL COMPONENT 'file://component_validate_password';
mysql> SELECT * FROM mysql.component;
+--------------+--------------------+------------------------------------+
| component_id | component_group_id | component_urn                      |
+--------------+--------------------+------------------------------------+
|            1 |                  1 | file://component_validate_password |
+--------------+--------------------+------------------------------------+

mysql> SHOW GLOBAL VARIABLES LIKE 'validate_password%';
+--------------------------------------+--------+
| Variable_name                        | Value  |
+--------------------------------------+--------+
| validate_password.check_user_name    | ON     | 
| validate_password.dictionary_file    |        |
| validate_password.length             | 8      |
| validate_password.mixed_case_count   | 2      |
| validate_password.number_count       | 2      |
| validate_password.policy             | STRONG |
| validate_password.special_char_count | 2      |
+--------------------------------------+--------+
```

비밀번호 정책은 세가지 중 하나 선택 가능  
1. `LOW`: 비밀번호 길이만 검증  
2. `MEDIUM`: 기본값, 숫자/대소문자/특수문자 배합까지 검증  
3. `STRONG`: 금칙어 여부까지 검증

금칙어 파일은 금칙어들을 한 줄에 하나씩 기록해서 텍스트 파일로 저장  
금칙어 검증은 비밀번호 정책이 `STRONG`인 경우에만 동작하기 때문에 같이 설정 필수  
금칙어 모음: https://github.com/danielmiessler/SecLists/blob/master/Passwords/Common-Credentials/10k-most-common.txt

```sql
SET GLOBAL validate_password.dictionary_file='prohibitive_word.data';
SET GLOBAL validate_password.policy='STRONG';
```

<br>

### 이중 비밀번호
사용중인 데이터베이스 계정은 비밀번호를 주기적으로 변경하기 어려움  
8.0 버전부터 2개의 값을 동시에 사용할 수 있는 기능 추가(dual password)  
2개의 비밀번호는 `primary`와 `secondary`로 구분  
밀어내기 식으로 비밀번호를 변경할 때마다 기존 `primary` 비밀번호가 `secondary`로 변경  
응용 프로그램에서 모두 `primary` 비밀번호로 변경후 배포 완료되면 `secondary` 비밀번호 삭제 권장  

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'old_password';
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password' RETAIN CURRENT PASSWORD;

## secondary 삭제
ALTER USER 'root'@'localhost' DISCARD OLD PASSWORD;
```

<br>

## 권한(Privilege)
권한은 글로벌 권한과 객체 권한으로 구분  
객체 권한은 `GRANT` 명령시 특정 객체를 필수적으로 명시  
글로벌 권한은 `GRANT` 명령시 특정 객체 명시 불가  

### 글로벌 권한
| 권한 | Grant 테이블 칼럼명 | 권한 범위 |
|--|--|--|
| FILE | File_priv | 파일 |
| CREATE ROLE | Create_role_priv | 서버 관리 |
| CREATE TABLESPACE | Create_tablespace_priv | 서버 관리 |
| CREATE USER | Create_user_priv | 서버 관리 |
| DROP ROLE | Drop_role_priv | 서버 관리 |
| PROCESS | Process_priv | 서버 관리 |
| PROXY | See proxies_priv table | 서버 관리 |
| RELOAD | Reload_priv | 서버 관리 |
| REPLICATION CLIENT | Repl_client_priv | 서버 관리 |
| REPLICATION SLAVE | Repl_slave_priv | 서버 관리 |
| SHOW DATABASES | show_db_priv | 서버 관리 |
| SHUTDOWN | Shutdown_priv | 서버 관리 |
| SUPER | Super_priv | 서버 관리 |
| USAGE | Synonym for "no privileges" | 서버 관리 |
| ALL [PRIVILEGES] | Synonym for "all privilleges" | 서버 관리 |

<br>

### 객체 권한
| 권한 | Grant 테이블 칼럼명 | 권한 범위 |
|--|--|--|
| EVENT | Event_priv | 데이터베이스 |
| LOCK TABLES | Lock_tables_priv | 데이터베이스 |
| REFERENCES | References_priv | 데이터베이스/테이블 |
| CREATE | Create_priv | 데이터베이스/테이블/인덱스 |
| GRANT OPTION | Grant_priv | 데이터베이스/테이블/스토어드 프로그램 |
| DROP | Drop_priv | 데이터베이스/테이블/뷰 |
| ALTER ROUTINE | Alter_routine_priv | 스토어드 프로그램 |
| CREATE ROUTINE | Create_routine_priv | 스토어드 프로그램 |
| EXECUTE | Execute_priv | 스토어드 프로그램 |
| ALTER | Alter_priv | 테이블 |
| CREATE TEMPORARY TABLES | Create_tmp_table_priv | 테이블 |
| DELETE | Delete_priv | 테이블 |
| INDEX | Index_priv | 테이블 |
| TRIGGER | Trigger_priv | 테이블 |
| INSERT | Insert_priv | 테이블/칼럼 |
| SELECT | Select_priv | 테이블/칼럼 |
| UPDATE | Update_priv | 테이블/칼럼 |
| CREATE VIEW | Create_view_priv | 뷰 |
| SHOW VIW | Show_view_priv | 뷰 |
| ALL [PRIVILEGES] | Synonym for "all privilleges" | 서버 관리 |

<br>

### 동적 권한
위의 글로벌 및 객체 권한은 정적 권한  
8.0 버전 이후 동적 권한이 더 추가  
서버가 시작되면서 동적으로 생성하는 권한, 예를 들어 서버 컴포넌트나 플러그인이 설치될때 등록되는 권한들  
기존의 `SUPER` 권한을 쪼개서 동적 권한으로 구분  

| 권한 | 권한 범위 |
|--|--|
| INNODB_REDO_LOG_ARCHIVE | 리두 로그 관리 |
| RESOURCE_GROUP_ADMIN | 리소스 관리 |
| RESOURCE_GROUP_USER | 리소스 관리 |
| BINLOG_ADMIN | 백업/복제 관리 |
| BINLOG_ENCRYPTION_ADMIN | 백업/복제 관리 |
| BACKUP_ADMIN | 백업 관리 |
| CLONE_ADMIN | 백업 관리 |
| GROUP_REPLICATION_ADMIN | 복제 관리 |
| REPLICATION_APPLIER | 복제 관리 |
| REPLICATION_SLAVE_ADMIN | 복제 관리 |
| CONNECTION_ADMIN | 서버 관리 |
| ENCRYPTION_KEY_ADMIN | 서버 관리 |
| PERSIST_RO_VARIABLES_ADMIN | 서버 관리 |
| ROLE_ADMIN | 서버 관리 |
| SESSION_VARIABLES_ADMIN | 서버 관리 |
| SET_USER_ID | 서버 관리 |
| SHOW_ROUTINE | 서버 관리 |
| SYSTEM_USER | 서버 관리 |
| SYSTEM_VARIABLES_ADMIN | 서버 관리 |
| TABLE_ENCRYPTION_ADMIN | 서버 관리 |
| VERSION_TOKEN_ADMIN | 서버 관리 |
| XA_RECOVER_ADMIN | 서버 관리 |
| APPLICATION_PASSWORD_ADMIN | 이중 비밀번호 관리 |
| AUDIT_ADMIN | Audit 로그 관리 |

<br>

각 권한의 특성에 따라 ON 절에 명시되는 오브젝트 상이  
존재하지 않는 사용자에 경우 오류 발생  
글로벌 권한은 특정 오브젝트에 부여될 수 없기 때문에 `*.*` 사용  

```sql
GRANT privilege_list ON db.table TO 'user'@'localhost';
GRANT SUPER ON *.* TO 'user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON employees.* TO 'user'@'localhost';
```

<br>

각 계정이나 권한에 부여된 권한을 확인하기 위해서 `SHOW GRANTS` 명령 사용 가능  
또는 표 형태로 보기 위해서 관련 테이블 참조 가능  

| 권한 | 저장소 테이블 | 설명 |
|--|--|--|
| 정적 권한 | mysql.user | 계정 정보 및 계정 역할에 부여된 글로벌 권한 |
| 정적 권한 | mysql.db | 계정이나 역할에 DB 단위로 부여된 권한 |
| 정적 권한 | mysql.tables_priv | 계정이나 역할에 테이블 단위로 부여된 권한 |
| 정적 권한 | mysql.columns_priv | 계정이나 역할에 칼럼 단위로 부여된 권한 |
| 정적 권한 | mysql.procs_priv | 계정이나 역할에 스토어드 프로그램 단위로 부여된 권한 |
| 동적 권한 | mysql.global_grants | 계정이나 역할에 부여되는 동적 글로벌 권한 |

<br>

## 역할(Role)
8.0 버전부터 권한을 묶어서 약할로 사용 가능  

```sql
## 역할 생성 및 권한 부여
## CREATE ROLE 'role_emp_read'@'%', 'role_emp_write'@'%';
CREATE ROLE role_emp_read, role_emp_write;

GRANT SELECT ON employees.* TO role_emp_read;
GRANT INSERT, UPDATE, DELETE ON employees.* TO role_emp_write;

## 계정에 역할 부여
GRANT role_emp_read TO reader@'127.0.0.1';
GRANT role_emp_read, role_emp_write TO writer@'127.0.0.1';
```

<br>

역할을 부여한 후 바로 데이터를 조회하거나 변경하려고 할때 권한 오류 발생  
실제 역할은 부여됐지만 계정의 활성화된 역할이 없음을 확인 가능, 수동으로 역할 활성화 필수  

```
linux> mysql -h127.0.0.1 -ureader -p
mysql> SELECT * FROM employees.employees LIMIT 10;
ERROR 1142 (42000): SELECT command denied to user 'reader'@'localhost' for table 'employees'

mysql> SELECT current_role();
+----------------+
| current_role() |
+----------------+
| NONE           |
+----------------+

mysql> SET ROLE 'role_emp_read';
mysql> SELECT current_role();
+---------------------+
| current_role()      |
+---------------------+
| 'role_emp_read'@'%' |
+---------------------+
```

<br>

만약 로그인과 동시에 부여된 역할을 자동으로 활성화하려면 `activate_all_roles_on_login` 시스템 변수값 설정  

```sql
SET GLOBAL activate_all_roles_on_login=ON;
```

<br>

내부적으로 역할과 계정은 동일한 객체로 취급  
하나의 사용자 계정에 다른 사용자 계정이 가진 권한을 병합해서 권한 제어가 가능해진 것  
서버는 계정과 역할을 구분할 필요가 없기 때문에 굳이 구분하지 않고 저장  
만약 계정의 호스트와 역할의 호스트가 상이한 경우, 역할의 호스트는 무시되고 반영  

```
mysql> SELECT user, host, account_locked FROM mysql.user;
+----------------+-----------+----------------+
| user           | host      | account_locked |
+----------------+-----------+----------------+
| role_emp_read  | %         | Y              |
| role_emp_write | %         | Y              |
| reader         | 127.0.0.1 | N              |
| writer         | 127.0.0.1 | N              |
| root           | localhost | N              |
+----------------+-----------+----------------+
```

<br>

각 계정이나 권한에 부여된 권한을 확인하기 위해서 `SHOW GRANTS` 명령 사용 가능  
또는 표 형태로 보기 위해서 관련 테이블 참조 가능  

| 저장소 테이블 | 설명 |
|--|--|
| mysql.default_roles | 계정별 기본 역할 |
| mysql.role_edges | 역할에 부여된 역할 관계 그래프 |

<br>
