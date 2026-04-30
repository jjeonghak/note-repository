# 레디스 데이터 백업

## 데이터 영구 저장
복제는 가용성을 위한 것이고 백업은 장애 상황에서의 복구에 필요  
레디스를 캐시가 아닌 영구 저장소 용도로 사용한다면 백업이 필수  

<br>

<img width="500" height="200" alt="aof_and_rdb" src="https://github.com/user-attachments/assets/23b54f39-32f7-49bb-9ac9-fcd621484678" />


`AOF(Append Only File)`: 처리한 모든 쓰기 작업을 차례로 기록, 복원 시에는 파일을 다시 읽어가며 데이터 재구성  
`RDB(Redis Database)`: 일정 시점에 메모리에 저장된 데이터 스냅샷 저장  

<br>

`RDB` 방식은 `AOF`보다 빠르게 복원되고 여러 시점 백업본 저장 가능, 하지만 특정 시점으로(스냅샷 없는) 복구 불가능  
일반적인 데이터베이스만큼의 안정성이 필요한 경우 두 옵션을 동시에 사용하는 것을 권장  
레디스 데이터 복원 시점은 서버가 재시작될 때뿐이며 실행 도중에는 불가능  
재시작될 때 `AOF`, `RDB` 파일 존재 여부를 확인하고 둘 다 존재하는 경우 `AOF` 파일을 로드  

<br>

### RDB 데이터 백업
설정 파일에서 특정 조건에 파일이 자동으로 저장되도록 지정 가능  
사용자가 원하는 시점에 커맨드를 이용해서 수동으로 생성 가능
복제 기능을 사용한다면 자동으로 생성  

<br>

1. 특정 조건에 자동으로 생성  
여러 조건으로 설정 가능  
실행 중인 상태에서 동적으로 설정 파일을 변경해도 적용되지 않음  

```
save <기간<초>> <기간 내 변경된 키의 개수>
dbfilename <RDB 파일 이름>
dir <RDB 파일 저장 경로>
```

2. 수동 생성  
`SAVE`, `BGSAVE` 커맨드를 이용해서 원하는 시점에 직접 생성 가능  
`SAVE` 커맨드는 동기 방식으로 모든 클라이언트 명령을 차단하고 저장  
`BGSAVE`는 `fork` 호출로 자식 프로세스를 생성해서 백그라운드에서 저장  
`LASTSAVE` 커맨드로 정상적으로 저장됐는지 확인 가능  

3. 복제를 사용하는 경우 자동 생성
`REPLICAOF` 커맨드를 이용해 복제를 요청하면 마스터 노드에서 파일 생성 후 복제본에 전달

<br>

### AOF 데이터 백업
모든 쓰기 작업의 로그(`RESP`)를 차례로 기록  
실수로 `FLUSHALL` 커맨드로 데이터를 모두 날려도 AOF 파일을 직접 열어 해당 커맨드만 삭제한 후 재시작으로 복구 가능  
설정 파일에서 `appendonly` 옵션을 yes로 지정하면 주기적으로 저장  
메모리에 영향이 없는 커맨드(조회, 잘못된 쓰기)는 무시되어 기록되지 않음  

```
appendonly yes
appendfilename "appendonly.aof"
appenddirname "appendonlydir"
```

<br>

항상 사용자가 실행한 커맨드를 그대로 저장하는 것은 아님  
예를 들어 블로킹 기능을 지원하는 `BRPOP` 커맨드는 `RPOP` 커맨드로 기록  
인스턴스 실행 시간에 비례해서 파일 크기가 계속 증가  

<br>

### AOF 파일 재구성
지속적으로 커지는 `AOF` 파일을 주기적으로 압축시키는 재구성 작업 필요  
특정 조건에 자동으로 재구성되도록 설정 가능하며 사용자가 원하는 시점에 직접 커맨드로 재구성 가능  
이때 저장된 파일을 사용하는 것이 아닌 메모리에 있는 데이터를 읽어와서 새로운 파일로 저장하는 형태로 동작  
기본 옵션인 `aof-use-rdb-preamble yes`를 수정하지 않는다면 이 데이터는 `RDB` 파일 형태로 저장  
파일 재구성도 `fork`를 사용해서 자식 프로세스가 재구성  

<br>

<img width="500" height="200" alt="aof_and_manifest" src="https://github.com/user-attachments/assets/c5a40910-c426-4249-89d1-38eaf0f3ae2c" />

기본이 되는 바이너리 형태의 `RDB` 파일, 증가하는 `RESP`의 텍스트 형태의 `AOF` 파일로 나누어 데이터 관리  
현재 레디스가 바라보고 있는 파일이 어떤 것인지 나타내는 매니페스트 파일을 추가적으로 도입  
`AOF` 재구성될 때마다 파일명의 번호 그리고 매니페스트 파일 내부의 `seq` 값도 1씩 증가  

<br>

1. `fork`를 이용해 자식 프로세스 생성, 자식 프로세스는 레디스 메모리의 데이터를 신규로 생성한 임시 파일에 저장  
2. 백그라운드로 이전 과정이 진행되는 동안 메모리 데이터 변경 내역은 신규 `AOF` 파일에 저장
3. 재구성 과정이 끝나면 임시 매니페스트 파일을 생성, 변경된 버전으로 매니페스트 파일 내용 업데이트  
4. 생성된 임시 매니페스트 파일로 기존 매니페스트 파일을 덮어 씌우고 이전 버전의 `AOF`, `RDB` 파일 삭제  

<br>

### 자동 AOF 재구성
`auto-aof-rewrite-percentage` 옵션은 파일을 다시 쓰기 위한 시점을 정함  
마지막으로 저장된 파일의 크기는 `INFO Persistence` 커맨드로 확인할 수 있는 `aof_base_size` 값  

```
> INFO Persistence
# Persistence
...
aof_current_size:186830
aof_base_size:145802
...
```

<br>

### 수동 AOF 재구성
`BGREWRITEAOF` 커맨드를 사용해서 원하는 시점에 직접 파일 재구성 가능  
자동 재구성 때와 동일하게 동작  

<br>

### AOF 타임스탬프
`aof-timestamp-enabled yes` 옵션을 통해 타임스탬프도 함께 저장  
레디스 기본 제공 `redis-check-aof` 프로그램을 통해 타임스탬프를 이용한 버전 관리 가능  

```
$ src/redis-check-aof --truncate-to-timestamp 1669532844 appendonlydir/appendonly.aof.manifest'
Start checking Multi Part AOF
Start to check BASE AOF (RDB format).
...
Successfully truncated AOF appendonly.aof.15.incr.aof to timestamp 1669532844
ALL AOF files and mainfest are valid
```

<br>

### AOF 파일 복원
시점 복원에서 사용한 `redis-check-aof` 프로그램은 파일 손상이 있는 경우 사용  
레디스가 의도치 않은 장애로 중단된 경우 AOF 파일의 상태 확인 가능  
`fix` 옵션을 이용해서 해결 가능  

```
$ src/redis-check-aof appendonlydir/appendonly.aof.manifest
Start checking Multi Part AOF
Start to check BASE AOF (RDB format).
...
RDB preamble is OK, proceeding with AOF tail...
...
AOF appendonly.aof.15.incr.aof is not valid. Use the --fix option to try fixing it.
```

<br>

### AOF 파일 안전성
파일에 데이터를 저장하면 데이터는 커널 영역의 OS 버퍼에 임시로 저장  
운영체제가 판단하기에 커널이 여유롭거나 최대 지연 시간에 도달한 경우 데이터를 실제 디스크에 내려씀  
`FSYNC` 명령어는 커널의 OS 버퍼에 저장된 내용을 디스크에 내리도록 강제하는 시스템 콜  
AOF 파일을 저장할 때 `APPENDFSYNC` 옵션을 사용하면 `FSYNC` 호출을 제어 가능  
- `APPENDFSYNC no`: `WRITE` 시스템 콜 호출, 가장 빠른 쓰기 성능  
- `APPENDFSYNC always`: `WRITE`와 `FSYNC` 시스템 콜 호출, 가장 느린 쓰기 성능
- `APPENDFSYNC everysec`: 1초에 한 번씩만 `FSYNC` 시스템 콜 호출, 기본 옵션  

<br>

### 백업 주의사항
`BGSAVE` 커맨드는 자식 프로세스를 생성하고 이때 `Copy-On-Write` 방식 사용  
최악의 경우 기존 메모리 용량의 2배를 사용  

<br>
