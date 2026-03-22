# 복제
가용성이란 일정 기간 동안 서비스를 정상적으로 사용할 수 있는 시간의 비율  
레디스의 고가용성을 위해서는 아래 두 가지 기능 필수
- 복제: 마스터 노드의 데이터를 복제본 노드로 실시간 복사
- 자동 페일오버: 마스터 노드의 장애를 감지해 자동으로 복제본 노드로 리다이렉션

<br>

## 레디스 복제 구조
다른 데이터베이스는 멀티 마스터 복제 구조를 제공, 모든 노드가 마스터이면서 슬레이브가 될 수 있는 구조  
레디스는 기본적으로 복제본 노드는 읽기 전용으로 멀티 마스터 구조를 지원하지 않음  

<br>

### 복제 구조 구성
마스터 노드의 정보를 입력하면 복제 연결이 시작  
모든 쓰기 커맨드는 마스터 노드에서 실행되며 복제본은 마스터를 지속적으로 감시  
여러 개의 복제본 연결이 가능하지만 마스터는 오로지 하나  

```
REPLICAOF <master-ip> <master-port>
```

<br>

### 패스워드 설정
`ACL` 기능이 아닌 기본적인 패스워드 사용시에는 `masterauth` 옵션 사용  
마스터에는 `requirepass` 옵션으로 패스워드 값을 설정 가능  

```
> CONFIG SET masterauth mypassword
OK

> CONFIG REWRITE
OK
```

<br>

## 복제 메커니즘
버전 7 이전에서는 `repl-diskless-sync no`가 기본  

<img width="500" height="300" alt="replication_flow" src="https://github.com/user-attachments/assets/ac12f14f-86dd-45ed-b71e-5b34a8071be8" />

- `REPLICAOF` 커맨드로 복제 연결 시도
- 마스터 노드에서는 `fork` 자식 프로세스를 생성한 후 `RDB` 스냅샷을 생성
- 파일 생성 중 발생한 변경 사항은 `RESP` 형태로 마스터 복제 버퍼에 저장 
- 파일 생성 완료 후 복제본 노드로 복사
- 복제본에 저장된 모든 내용 삭제 후 파일을 이용해 데이터 로딩
- 복제 과정 중 버퍼링된 커맨드는 복제본으로 전달해 수행

<br>

이 모든 과정에 마스터 노드와 복제본 노드에 각각 로그 생성  

```
# 마스터 노드
10382:M 27 Nov 2022 20:28:57.862 * Replica <replica ip>:<replica port> asks for synchronization
10382:M 27 Nov 2022 20:28:57.862 * Partial resynchronization not accepted:
Replication ID mismatch (Replica asked for 'Sac5cc612718c97406aa02b8b1f1ffa9788503b1', my replication
IDs are '593637760bf0fff9e6477e7583bfe8b889aaabf' and '0000000000000000000000000000000000000')
10382:M 27 Nov 2022 20:28:57.862 * Starting BGSAVE for SYNC with target: disk
10382:M 27 Nov 2022 20:28:57.864 * Background saving started by pid 15591
15591:C 27 Mov 2022 20:28:57.872 * DB saved on disk
15591:C 27 Mov 2022 20:28:57.873 * Fork CoW for RDB: current 4 MB, peak 4 MB, average 4 MB
10382:M 27 Nov 2022 20:28:57.891 * Background saving terminated with success
10382:M 27 Nov 2022 20:28:57.892 * Synchronization with replica <replica ip>:<replica port> succeeded

# 복제본 노드
1071:S 27 Nov 2022 20:28:57.867 * Before turning into a replica, using my own master parameters to synth
esize a cached master: I may be able to synchronize with the new master with just a partial transter.
1071:S 27 Nov 2022 20:28:57.867 * Connecting to MASTER <master ip>:<master port>
1071:S 27 Nov 2022 20:28:57.867 * MASTER <-> REPLICA sync started
...
1071:S 27 Nov 2022 20:28:57.868 * Non blocking connect for SYNC fired the event.
1071:S 27 Nov 2022 20:28:57.868 * Master replied to PING, replication can continue...
1071:S 27 Nov 2022 20:28:57.869 * Trying a partial resynchronization (request 5ac5cc612718c97406aa02b8...
1071:S 27 Nov 2022 20:28:57.874 * Full resync from master: 593637760bf0fff9e6477e7583bfbe8b889aaabf:574
1071:S 27 Nov 2022 20:28:57.899 * MASTER <-> REPLICA sync: receiving 213641 bytes from master to disk
1071:S 27 Nov 2022 20:28:57.900 * Discarding previously cached master state.
1071:S 27 Nov 2022 20:28:57.900 * MASTER <-> REPLICA sync: Flushing old data
1071:S 27 Nov 2022 20:28:57.900 * MASTER <-> REPLICA sync: Loading DB in memory
1071:S 27 Nov 2022 20:28:57.903 * Loading RDB produced by version 6.2.4
1071:S 27 Nov 2022 20:28:57.903 * RDB age 0 seconds
1071:S 27 Nov 2022 20:28:57.903 * RDB memory usage when created 1.64 Mb
1071:S 27 Nov 2022 20:28:57.905 * Done loading RDB, keys loaded: 6118, keys expired: 0.
1071:S 27 Nov 2022 20:28:57.905 * MASTER <-> REPLICA sync: Finithed with success
```

<br>

버전 7 이후에서는 `repl-diskless-sync yes`가 기본  

<img width="500" height="300" alt="replication_flow_v7" src="https://github.com/user-attachments/assets/a9f07626-eb6e-4007-b129-fb568b397750" />

- `REPLICAOF` 커맨드로 복제 연결
- 마스터 노드는 소켓 통신을 이용해 복제본 노드에 바로 연결, `RDB` 파일을 생성과 동시에 점진적으로 소켓에 전송
- 파일 생성 중 발생한 변경 사항은 `RESP` 형태로 마스터 복제 버퍼에 저장  
- 소켓에서 읽어온 파일을 복제본의 디스크에 저장
- 복제본에 저장된 모든 데이터 삭제 후 파일 내용으로 데이터 로딩
- 복제 버퍼의 데이터를 복제본으로 전달해 수행

<br>

해당 방식은 이미 하나의 복제본으로 복제 연결이 시작된 경우 복제 과정이 끝나기 전까지 다른 복제본의 연결은 수행 불가  
`repl-diskless-sync-delay` 옵션을 이용해서 새로운 복제 연결이 들어오면 기본 시간을 대기한 후 복제 연결 시작  

```
# 마스터 노드
10382:M 27 Nov 2022 20:23:42.095 * Replica <replica ip>:<replica port> asks for synchronization
10382:M 27 Nov 2022 20:23:42.095 * Partial resynchronization not accepted:
Replication ID mismatch (Replica asked for 'Sac5cc612718c97406aa02b8b1f1ffa9788503b1', my replication
IDs are '593637760bf0fff9e6477e7583bfe8b889aaabf' and '0000000000000000000000000000000000000')
10382:M 27 Nov 2022 20:23:42.095 * Delay next BGSAVE for diskless SYNC
10382:M 27 Nov 2022 20:23:47.135 * Starting BGSAVE for SYNC with target: replicas sockets
10382:M 27 Nov 2022 20:23:47.138 * Background RDB transfer started by pid
10382:C 27 Nov 2022 20:23:47.149 * Fork CoW for RDB: current 6 MB, peak 6 MB, average 6 MB
10382:M 27 Nov 2022 20:23:47.149 # Diskless rdb transfer, done reading from pipe, 1 replicase still up.
10382:M 27 Nov 2022 20:23:47.154 * Background RDB transfer terminated with success
10382:M 27 Nov 2022 20:23:47.154 * streamed RDB transfer with replica <replica ip>:<replica port> succe
eded (socket). Waiting for REPLCONF ACK from slave to enable streaming
10382:M 27 Nov 2022 20:23:47.154 * Synchronization with replica <replica ip>:<replica port> succeeded

# 복제본 노드
...
1071:S 27 Nov 2022 20:23:42.102 * MASTER <-> REPLICA sync started
1071:S 27 Nov 2022 20:23:42.102 * REPLICAOF <master ip>:<master port> enabled (user request from 'id=10
addr=127.0.0.1:47434 laddr=127.0.0.1:6379 fd=8 name= age=6 idle=0 flags=N db=0 sub=0 psub=0 ssub=0 multi
=-1 qbuf=48 qbuf-free=20426 argv-mem=25 multi-mem=0 rbs=1024 rbp=0 obl=0 oll=0 omem=0 tot-mem=22321 even
ts=r cmd=replicaof user=default redir=-1 resp=2')
1071:S 27 Nov 2022 20:23:42.103 * Non blocking connect for SYNC fired the event.
1071:S 27 Nov 2022 20:23:42.103 * Master replied to PING, replication can continue...
1071:S 27 Nov 2022 20:23:42.104 * Trying a partial resynchronization (request dcd3f6c2fdfdf8a78c337bf...
1071:S 27 Nov 2022 20:23:47.144 * Full resync from master: 593637760bf0fff9e6477e7583bfbe8b889aaabf:154
1071:S 27 Nov 2022 20:23:47.156 * MASTER <-> REPLICA sync: receiving streamed RDB from master with EOF
1071:S 27 Nov 2022 20:23:47.160 * Discarding previously cached master state.
1071:S 27 Nov 2022 20:23:47.160 * MASTER <-> REPLICA sync: Flushing old data
1071:S 27 Nov 2022 20:23:47.160 * MASTER <-> REPLICA sync: Loading DB in memory
1071:S 27 Nov 2022 20:23:47.161 * Loading RDB produced by version 7.0.5
1071:S 27 Nov 2022 20:23:47.161 * RDB age 0 seconds
1071:S 27 Nov 2022 20:23:47.161 * RDB memory usage when created 1.58 Mb
1071:S 27 Nov 2022 20:23:47.163 * Done loading RDB, keys loaded: 6118, keys expired: 0.
1071:S 27 Nov 2022 20:23:47.163 * MESTER <-> REPLICA sync: Finished with success
```

<br>

















