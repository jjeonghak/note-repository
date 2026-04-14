# 클러스터
스케일 업은 서버의 하드웨어 사양을 업그레이드 하는 것  
스케일 아웃은 장비를 추가해 시스템을 확장시키는 것  

<br>

### 확장성
레디스 운영 중 키 이빅션(`eviction`)이 자주 발생한다면 스케일 업 고려 가능  
레디스 인스턴스의 `maxmemory` 만틈 데이터가 차 있을 때 다시 저장하는 경우 발생  
하지만 단일 스레드 동작에 의해 CPU를 멀티 코어로 추가한다고 하더라도 동시에 활용 불가  

<br>

### 데이터 샤딩

<img width="500" height="300" alt="sharding" src="https://github.com/user-attachments/assets/fd334795-176e-40f7-97f5-7e05fbee0ea0" />

데이터 저장소를 수평 확장하며 여러 서버 간에 데이터를 분할하는 데이터베이스 아키텍처 패턴  
데이터는 키를 이용해 샤딩되며 하나의 키는 항상 하나의 마스터 노드에 매핑  
클라이언트가 다른 노드에 데이터를 쓰거나 읽으려 하는 경우 키가 할당된 마스터 노드로 리다이렉션  

<br>

### 고가용성

<img width="500" height="300" alt="cluster_full_mesh" src="https://github.com/user-attachments/assets/70784cc6-427b-4f5c-80a1-2b52a0fb43de" />

클러스터는 각각 최소 3대의 마스터, 복제본 노드를 갖도록 구성  
클러스터 내의 노드들은 클러스터 버스라는 독립적인 통신 사용  
모든 레디스 클러스터 노드는 다른 레디스 클러스터 노드에서 들어오는 연결을 수신하기 위한 추가 TCP 포트 오픈  
클라이언트로부터 커맨드를 받는 포트와 독립되게 동작, 일반적으로 일반포트에 10000을 더한 값으로 설정  
클러스터는 모든 노드가 다른 모든 노드와 연결된 풀 메쉬(`full-mesh`) 토폴로지 형태  

<br>

## 클러스토 동작 방법

### 해시슬롯을 이용한 데이터 샤딩

<img width="500" height="250" alt="hashslot" src="https://github.com/user-attachments/assets/d58744d5-e504-4b7b-afb9-5d22cd7edbc2" />

레디스는 총 `16384`개의 해시슬롯을 보유, 마스터 노드는 해시슬롯을 나눠서 보유  
레디스에 입력되는 모든 키는 하나의 해시슬롯에 매핑

```
HASH_SLOT = CRC16(key) mod 16384
```

<br>

### 해시태그

<img width="500" height="250" alt="mget_with_cluster" src="https://github.com/user-attachments/assets/285dfdf0-fe2a-44e9-858e-8ddfa823ed41" />

클러스터를 사용 중인 경우 다중 키 커맨드를 이용한 여러 키 접근 불가  
클러스터는 키를 이용해 커맨드를 처리할 마스터로 클라이언트 연결을 리다이렉션하기 때문에 처리 불가  
해시태그는 키에 대괄호를 사용한 부분만 해시한 값  
이를 이용해서 연관되어 있는 데이터를 같은 마스터에 저장 가능  

```
user:{123}:profile
user:{123}:account
```

<br>

### 자동 재구성
센티널과 마찬가지로 클러스터 구조에서도 복제와 자동 페일오버 사용 가능  
센티널은 별도의 센티널 인스턴스가 필요하지만 클러스터는 레디스 노드가 서로를 감시  
모든 노드는 클러스터 버스를 통해 통신하며 장애 발생시 자동으로 클러스터 구조를 재구성  
클러스터 내의 마스터가 하나라도 정상 상태가 아닐 경우 전체 클러스터 사용 불가  
레디스 클러스터에서 일부 해시슬롯을 사용하지 못하게 되면 전체 상태가 `fail`  

<br>

<img width="500" height="600" alt="auto_relication_migration" src="https://github.com/user-attachments/assets/203d2aa5-d083-499f-a73d-2dbd8d073457" />

클러스터는 각 마스터에 연결된 복제본 노드의 불큔형을 파악  
이때 마이그레이션되는 복제본은 가장 많은 수의 복제본이 연결된 마스터의 노드 ID가 가장 작은 순으로 선택  

<br>

## 클러스터 실행
클러스터 모드는 최소 3개의 마스터 노드 필수  
일반적으로 운영을 위해서는 3개의 추가 복제본도 필수  

<br>

### 클러스터 초기화
`cluster-enalbe yes` 설정을 통해 클러스터 모드로 변경  

<img width="600" height="250" alt="cluster_init" src="https://github.com/user-attachments/assets/aaf13e7c-5d56-40fd-bf8f-ec019ef8e053" />

```
redis-cli -cluster create [host:port] --cluster-replicas 1
```

<br>

### 클러스터 상태 조회
`CLUSTER NODES` 커맨드를 통해 랜덤으로 클러스터 내의 노드들을 순서 없이 출력  

```
$ redis-cli cluster nodes
73abfbb3872609862c9fcc229cdflc3a3c0f2d05 192.168.0.22:6379@16379 master - 0
1670429890051 2 connected 5461-10922
f6cl580：1602a4f5e89458945362ce3e6cfld6cd3 192.168.0.66:6379(316379 slave 73abf
bb3872609862c9fcc229cdflc3a3c0f2d05 0 1670429890553 2 connected
52e66ec38afe31063a9821f03a9dab9ae3cdf9dd 192.168.0.44:6379@16379 slave ablb4
edfa9085bl04fc3fd9f3f9d53740f7dea66 0 1670429889000 3 connected
ablb4edfa9085bl04fc3fd9f3f9d53740f7dea66 192.168.0.33:6379016379 master - 0
1670429889000 3 connected 10923-16383
5315c78clca9f 39aceab55357cl69cl93756a1445 192.168.0.11:6379(016379
myself,master - 0 1670429888000 1 connected 0-5460
c/fa336489d69e3dc9e5068374al9ca9376e9c20 192.168.0.55:6379@16379 slave 5al5c
78clea9f39aceab55357d69cl93756al445 0 1670429890252 1 connected
```

<br>

### 클러스터 접근 및 리다이렉션
레디스 클러스터 접속은 클러스터 모드를 지원하는 레디스 클라이언트 필요  

```
$ redis-cli
127.0.0.1:6379> set user:1 true
(error) MOVED 10778 192.168.0.22:6379
```

<br>

<img width="500" height="500" alt="set_data_with_cluster_mode" src="https://github.com/user-attachments/assets/01d3a95c-5748-4373-8d9f-9803d608de32" />

Jedis, Redisson 등 레디스 클라이언트는 클러스터 모드 기능 제공  
`-c` 옵션을 추가해 클러스터 모드로 사용 가능  

```
$ redis-cli -c
127.0.0.1:6379> set user:1 true
-> Redirected to slot [10778] located at 192.168.0.22:6379
OK
192.168.0.22:6379>
```

<br>

## 클러스터 운영

### 클러스터 리샤딩
리샤딩은 마스터 노드가 보유한 해시슬롯 중 일부를 다른 마스터로 이전하는 것  
`cluster reshard` 옵션을 통해 수행 가능  

```
$ redis-cli --cluster reshard 192.168.0.66 6379
>>> Performing Cluster Check (using node 192.168.0.66:6379)
S: f6c15801602a4f5e89458945362ce3e6cf1dcd3 192.168.0.66:6379
   slots: (0 slots) slave
M: 5al5c78clca9f39aceab55357d69cl93756al445 192.168.0.11:6379
   slots: [0-5460] (5461 slots) master
   1 additional replica(s)
...
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
How many slots do you want to move (from 1 to 16384)?
```

<br>

클러스터에 속한 여러 노드 둥 하나의 노드를 지정하면 해당 노드가 속한 클러스터 구조를 파악  
이동시킬 슬롯의 개수를 지정한 후 해시슬롯을 받을 노드 ID를 입력  
`all`은 다른 노드에서 조금씩 슬롯을 가져오는 상황  
`done`은 해시슬롯을 가져올 마스터 ID를 하나씩 지정한 후 입력  

```
How many slots do you want to move (from 1 to 16384)? 100
What is the receving node ID? ablb4edfa9085bl04fc3fd9f3f9d53740f7dea66
Please enter all the source node IDs.
  Type 'all' to use all the nodes as source nodes for the hash slots.
  Type 'done' once you entered all the source nodes IDs.
Source node #1:
```

<br>

### 클러스터 리샤딩 - 간단 버전
슬롯 이동이 잦아 자동화가 필요한 경우 아래와 같은 커맨드로 사용자 인터렉션 없이 사용 가능  

```
redis-cli --cluster reshard <host>:<port> --cluster-from <node-id>
--cluster-to <node-id> --cluster-slots <number of slots> --cluster-yes
```

<br>

### 클러스터 확장 - 신규 노드 추가
노드를 마스터/복제본 용도로 추가하려면 해당 노드는 어떠한 데이터도 저장되지 않은 상태 필수  
추가하고자 하는 노드도 마찬가지로 설정 파일에 `cluster-enabled yes` 옵션 필수  

<br>

신규 마스터를 추가하려면 새로운 노드와 기존 클러스터 노드를 하나씩 지정  
새로운 노드를 추가하기 전 기존 노드의 상태 확인 과정 존재  
새롭게 추가된 마스터 노드는 해시슬롯을 할당받지 못한 상태이기 때문에 리샤딩 과정 필수  

```
redis-cli --cluster add-node <추가할 ip:port> <기존 ip:port>
```

<br>

복제본을 추가하려면 마스터를 추가할 때와 동일하나 `--cluster-slave` 옵션 추가  
복제본의 마스터가 될 노드를 지정 가능, 해당 옵션이 없다면 임의의 마스터의 복제본으로 연결  
클러스터의 복제본이 대칭적인 구조가 아니라면 복제본이 가장 적은 마스터를 파악해서 연결  

```
redis-cli --cluster add-node <추가할 ip:port> <기존 ip:port>
--cluster-slave [--cluster-master-id <기존 마스터 id>]
```

<br>

### 노드 제거
노드를 제거하려면 `del-node` 커맨드 사용
제거할 노드가 마스터/복제본 상관없이 같은 방식으로 삭제 가능  
하지만 마스터 노드의 경우 제거하기 전 노드에 저장된 데이터가 없는 상태여야 가능  
즉, 할당된 해시슬롯이 하나도 없도록 다른 노드에 리샤딩하는 작업이 선행 필수  

```
redis-cli --cluster del-node 192.168.0.11:6379  73173c7c742a5659a25e41e0cf288fe24429e2fd
>>> Removing node 73173c7c742a5659a25e41e0cf288fe24429e2fd from cluster 192.168.0.11:6379
>>> Sending CLUSTER FORGET messages to the cluster...
>>> Sneding CLUSTER RESET SOFT to the deleted node.
```

<br>

제거될 노드에서 클러스터 구성 데이터를 지우는 것뿐만 아니라 다른 노드에게도 해당 노드를 지우라는 커맨드 필수  
`CLUSTER FORGET <node-id>` 커맨드를 수신한 노드는 노드 테이블에서 해당 노드 정보 제거  
제거될 노드에는 `CLUSTER RESET` 커맨드 수행, 기본값은 `SOFT`  
`HARD` 옵션은 아래의 과정이 모두 수행, `SOFT`는 3번 과정까지만 수행  
1. 복제본이라면 마스터로 전환, 모든 데이터셋 삭제(마스터였지만 데이터가 존재하는 경우는 리셋 작업 중단)  
2. 해시슬롯이 존재하면 모든 슬롯 해제  
3. 클러스터 구성 내의 다른 노드 데이터 초기화  
4. 에포크 관련 모든 값이 0으로 초기화  
5. 노드의 ID가 새로운 임의 ID로 변경  

<br>

### 레디스 클러스터로 데이터 마이그레이션
기존에 싱글 혹은 센티널 구성으로 사용하고 있던 레디스 인스턴스를 클러스터로 마이그레이션 가능  
기존에 다중 키 커맨드를 사용하지 않은 경우는 저장 로직이 문제되지 않지만 사용한 경우는 해시태그를 사용하도록 수정 필요  
데이터가 저장될 클러스터 노드는 해시슬롯 `16384`개가 정상적으로 할당된 상태  
운영중인 레디스 데이터는 마이그레이션하는 동안 클라이언트를 모두 중단 필수(마이그레이션 도중 발생하는 변경 커맨드가 반영되지 않음)  

```
redis-cli --cluster import 192.168.0.11:6379 --cluster-from 192.168.0.88:6379 --cluster-copy
```

<br>

### 복제본을 이용한 읽기 성능 향상
클라이언트는 기본적으로 키를 요청하면 키를 보유한 마스터 노드로 연결을 리다이렉션  
복제본을 읽기 전용으로 사용 가능  

```
$ redis-cli -h 192.168.0.55 -c
192.168.0.55:6379> readonly
OK
```

<br>

## 클러드터 동작 방법

### 하트비트 패킷
클러스터 노드들은 지속적으로 서로의 상태를 확인하기 위해 `PING`, `PONG` 패킷을 주고 받음  
이를 하트비트 패킷이라고 부르며 일반적으로 클러스터가 주고 받는 유형의 패킷에 가십 섹션이 추가된 형태  

<img width="500" height="350" alt="heartbeat" src="https://github.com/user-attachments/assets/49f8da5d-7485-4776-af71-d9cd4c629420" />

가십 섹션은 패킷을 발신하는 노드가 알고 있는 클러스터 내의 다른 노드 정보를 표시  
발신자 노드는 자신이 알고 있는 노드 중 랜덤한 몇 개의 노드만 가십 섹션에 포함  
이를 이용하면 알지 못하던 다른 노드를 받아들일 수 있고 장애 감지 가능  

<br>

### 해시슬롯 구성이 전파되는 방식
클러스터에서 해시슬롯의 구성은 아래 두가지 방법으로 전파  
해시슬롯 구성의 변경은 페일오버와 리샤딩 중에만 발생  
- 하트비트 패킷: 마스터 노드가 `PING`, `PONG` 패킷을 보낼 때 자신의 해시슬롯을 패킷 데이터에 추가  
- 업데이트 메시지: 에포크 값을 비교해서 신규 에포크 구성 정보를 포함한 업데이트 메시지 하트비트 패킷의 해시슬롯 구성을 업데이트  

<br>

### 노드 핸드셰이크
새로운 노드가 클러스터에 합류하기 위해서는 `CLUSTER MEET` 커맨드를 다른 노드에 전송  
수신한 노드는 자신이 알고 있는 다른 노드들에게 전파  
새로운 노드와 기존 노드들이 이 방식으로 풀 메쉬 연결  

<br>

### 리다이렉션
클러스터가 반환하는 리다이렉션에는 `MOVED`와 `ASK` 두가지 종류 존재  
- `MOVED`: 요청하는 해시슬롯이 있는 노드 반환, 앞으로의 요청은 해당 노드로 요청 강제
- `ASK`: 요청하는 쿼리를 수행할 노드 반환, 하지만 앞으로의 요청도 본인 노드로 재요청 강제  

<br>

<img width="550" height="300" alt="moved_redirection" src="https://github.com/user-attachments/assets/a4ce5990-a719-40e8-af5a-5bc8639ec089" />

레디스 노드는 클라이언트가 요청한 커맨드가 단일 키 커맨드인지 또는 다중키인 경우 동일한 해시슬롯인지 파악  
이후 키가 속한 해시슬롯을 포함한 마스터 노드를 탐색  
해시슬롯을 보유한 경우 원하는 데이터를 바로 반환, 아닌 경우 `MOVED` 에러로 클라이언트 응답  

<br>

<img width="550" height="500" alt="ask_redirection" src="https://github.com/user-attachments/assets/9a9482e2-2587-452b-95e1-9edaeae2f609" />

`ASK` 리다이렉션은 해시슬롯이 이동되는 과정에서만 발생  
리다이렉션 오류가 반환한 노드 정보로 쿼리를 재전송하지만 이후에 같은 키에 대한 쿼리를 기존의 전송한 노드로 재요청  
클라이언트는 리다이렉션 받은 노드로 해시슬롯 맵을 업데이트하지 않음  

<br>

### 장애 감지와 페일오버
클러스터 대부분의 노드가 특정 노드에 접근할 수 없다는 것을 인지한 경우 해당 노드의 상태 변경  
플래그는 `PFAIL`과 `FAIL` 사용  

<br>

`PFAIL`은 일부 노드에서 해당 노드에 접근할 수 없지만 아직 확실하진 않은 실패  
특정 노드에 `NODE_TIMEOUT` 시간 이상 도달할 수 없는 경우 해당 플래그로 표시  
마스터, 복제본에 관계없이 클러스터 내의 모든 노드들은 다른 노드에 해당 플래그 설정 가능  
`NODE_TIMEOUT`은 항상 `RTT`보다 큰 값 필수  

<br>

`FAIL`은 대다수 노드에서 해당 노드에 장애가 발생했음을 동의한 상태  
페일오버를 트리거시키기 위해서는 노드가 `PFAIL`이 아닌 `FAIL` 상태여야 가능  

<br>
