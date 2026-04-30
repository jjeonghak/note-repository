# 센티널
데이터를 저장하는 기존 레디스 인스턴스와는 다른 역할을 하는 별도의 프로그램  
자동 페일오버 기능을 사용해서 마스터 장애가 발생하더라도 레디스 다운타임 최소화  

<br>

<img width="500" height="200" alt="sentinel_behavior" src="https://github.com/user-attachments/assets/600ca469-7748-428f-a33f-cc67292dfdb0" />

- 모니터링: 마스터, 복제본 인스턴스 상태를 실시간으로 확인  
- 자동 페일오버: 마스터 비정상 상태 감지시 정상 상태 복제본 하나를 마스터로 승격  
- 구성 정보 안내: 클라이언트에게 마스터 정보 제공  

<br>

## 분산 시스템으로 동작
`SPOF` 방지를 위해서 최소 3대 이상일 때 정상적으로 동작하도록 설계  
하나의 센티널에 이상이 발생하더라도 다른 센티널이 역할 수행  
쿼럼(`quorum`) 알고리즘을 사용해서 마스터 페일오버 수행  

<br>

기본적으로 센티널 인스턴스는 물리적으로 서로 영향받지 않는 서버에서 실행  
보통 하나의 서버에 레디스 프로세스와 센티널 프로세스를 동시에 실행  
모든 레디스 프로세스는 `6379`, 센티널 프로세스는 `26379` 포트 사용  

<br>

센티널 프로세스는 `sentinel.conf` 설정 파일 필요  
실행될 포트, 모니터링할 마스터 이름, 쿼럼 값 지정  

```
port 26379
sentinel monitor master-test 192.168.0.11 6379 2
```

```
# redis-sentinel 사용
redis-sentinel /path/to/sentinel.conf

# redis-server 사용
redis-server /path/to/sentinel.conf --sentinel
```

<br>

`redis-cli`를 사용해서 센티널 인스턴스에 직접 접근 가능  

```
$ redis-cli -p 26379
sentinel> SENTINEL master master-test
 1) "name"
 2) "master-test"
 3) "ip"
 4) "192.168.0.11"
 5) "port"
 6) "6379"
...

sentinel> SENTINEL replicas master-test
1)  1) "name"
    2) "192.168.0.22:6379"
    3) "ip"
    4) "192.168.0.22"
    5) "port"
    6) "6379"
...
```

<br>

센티넬의 현재 상태가 쿼럼에 설정한 값을 유지하고 있는지 확인 가능  

```
sentinel> SENTINEL chquorum master-test
OK 3 usable Sentinels. Quorm and failover authorization can be reached

sentinel> SENTINEL chquorum master-test
(error) NOQUORUM 1 usable Sentinels. Not enough available Sentinels to reach
the specified quorum for this master. Not enough available Sentinels to
reach the majority and authorize a failover
```

<br>

정상적으로 센티널이 구성된 것을 확인한 후 페일오버 테스트 진행 권장  

```
# 수동 페일오버
SENINEL FAILOVER <master name>

# 자동 페일오버
redis-cli -h <master-host> -p <master-port> shutdown
```

<br>

### 센티널 운영
마스터와 복제본 노드에 `requirepass/masterauth` 옵션을 통해 패스워드 설정한 경우 센티널 설정도 필요  

```
sentinel auth-pass <master-name> <password>
```

<br>

모든 레디스 인스턴스는 `replica-priority` 값을 보유  
센티널이 페일오버를 진행할 때 복제본의 해당 값이 가장 작은 노드를 마스터로 선출  
센티널 실행 도중 모니터링할 마스터를 추가/제거/변경 가능  
여러 대의 센티널이 마스터를 모니터링 중이라면 각각의 센티널에 모두 설정을 적용 필수(설정 전파 안됨)  

```
SENTINEL MONITOR <master name> <ip> <port> <quorum>
SENTINEL REMOVE <master name>
SENTINEL SET <name> [<option> <value> ...]
SENTINEL CONFIG GET <configuration name>
SENTINEL CONFIG SET <configuration name> <value>
```

<br>

## 센티널 자동 페일오버 과정
### 1. 마스터 장애 상황 감지  
`down-after-milliseconds` 값 이상 동안 마스터에 보낸 `PING` 응답을 받지 못한 경우 마스터 다운 판단  



<br>

### 2. 실패 상태로 전환  

<img width="500" height="200" alt="subjectly_down" src="https://github.com/user-attachments/assets/3c7d0a65-29d5-4c7c-9600-e40fb657dfc4" />

마스터 응답을 받지 못한 센티널 노드는 마스터 상태를 우선 `sdown`(subjectly down)으로 플래깅  
이후 다른 센티널 노드들에게 아래 커맨드 전송(마스터 장애 사실 전파)  

```
SENTINEL is-master-down-by-addr <master-ip> <master-port> <current-epoch> <*>
```

<br>

<img width="500" height="200" alt="objectly_down" src="https://github.com/user-attachments/assets/8eda0179-cc95-48f9-9e50-79b4517cd2f7" />

커맨드를 받은 다른 센티널들은 해당 마스터 서버의 장애를 인지했는지 여부를 응답  
자기 자신을 포함해 쿼럼 값 이상의 센티널 노드에서 마스터 장애를 인지한 경우 마스터 상태를 `odown`(objectly down)으로 변경

<br>

### 3. 에포크 증가  
처음으로 마스터 노드를 `odown`으로 인지한 센티널 노드가 페일오버 과정을 시작  
페일오버를 시작하기 전 우선 에포크 값을 하나 증가  
에포크는 증가하는 숫자값으로 페일오버가 발생할 때마다 하나씩 증가  
동일한 에포크 값을 이용해서 페일오버 과정이 진행되는 동안 모든 센티널 노드는 같은 작업을 시도하는 것을 보장  

<br>

### 4. 센티널 리더 선출  

<img width="500" height="200" alt="leader_election" src="https://github.com/user-attachments/assets/2ccf920c-4820-4f4d-9244-106ad93bdc5e" />

에포크 값을 증가시킨 센티널은 다른 센티널에게 리더 선출을 위한 투표 메시지 전송  
이때 증가시킨 에포크 값을 함께 전달시켜 메시지를 받은 센티널 노드가 현재 자신의 에포크 값을 갱신시킴  

<br>

### 5. 마스터 승격
과반수 이상 센티널이 페일오버에 동의했다면 리더 센티널은 마스터가 될 수 있는 복제본을 선정  
아래의 자격이 있는 복제본 순으로 선출  
- `redis.conf` 파일에 명시된 `replica-priority`가 낮은 복제본
- 마스터로부터 더 많은 데이터를 수신한 복제본(`master_repl` 오프셋)
- 위의 조건이 동일하면 `runID` 사전 순으로 작은 복제본

<br>

### 6. 복제 연결 변경
기존 마스터에 연결된 다른 복제본은 새로 승격된 마스터의 복제본이 될 수 있도록 아래 커맨드 수행  

```
replicaof new-ip new-port
```

<br>

## 스플릿 브레인 현상
네트워크 파티션 이슈로 인해 분산 환경의 데이터 저장소가 끊어지고, 각 부분이 자신을 정상적인 서비스로 인식하는 현상  
만약 기존 마스터가 장애 회복 후 다시 동작하더라도 동일한 현상 발생  
- 에포크 값 확인: 현재 에포크 값을 확인한 후 자신이 구번임을 인지
- 강제 강등 명령: 센티널들은 새로운 마스터에 대한 `replicaof` 커맨드 전송  
- 데이터 동기화: 커맨드를 받은 구 마스터는 즉시 복제본으로 전환 후 기존 데이터 삭제

<br>
