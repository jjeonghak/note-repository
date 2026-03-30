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




















