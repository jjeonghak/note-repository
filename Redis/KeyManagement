//키 자동 생성 및 삭제 규칙
  stream, set, sorted set, hash 같이 하나의 키가 여러 아이템을 갖는 자료구조는 자동 키 생성 및 삭제

    1. 키가 존재하지 않을 때 아이템을 넣으면 아이템을 삽입하기 전에 빈 자료 구조 생성
      저장하고자 하는 키에 다른 자료 구조가 존재하는 경우 아이템 추가시 에러 반환

    2. 모든 아이템을 삭제하면 키도 자동으로 삭제(stream 예외)
    
    3. 키가 없는 상태에서 읽기 전용 커맨드 수행시 키가 있으나 비어있는 것처럼 동작


//키 조회
  1. EXISTS

      EXISTS key [key ...]

    키가 존재하는지 확인(존재하는 경우 1, 존재하지 않는 경우 0)

  2. KEYS

      KEYS pattern

    레드스에 저장된 모든 키를 조회해서 매칭되는 패턴에 해당하는 모든 키 반환
    얼마나 작업이 수행될지 예상할 수 없고 O(N)으로 동작하기 때문에 사용 금지
    패턴은 글롭 패턴(glob pattern) 스타일로 동작
      h?llo -> ? 자리의 어떠한 한개의 문자 가능
      h*llo -> * 자리의 어떠한 여러개(0개 포함) 문자 가능
      h[ae]llo -> a 또는 e만 가능
      h[^e]llo -> e를 제외한 문자 가능
      h[a-b]llo -> a 에서 b까지의 문자만 가능

  3. SCAN

      SCAN cursor [MATCH pattern] [COUNT count] [TYPE type]

    KEYS 커맨드를 대체해 키를 조회할 때 사용
    커서 기반 특정 범위의 키만 조회
    처음 반환값은 다음 SCAN 커맨드에 사용할 커서값(다음 페이지 값)
    즉 다시 처음 반환값이 0이 나올때까지 SCAN을 반복적으로 사용하면 KEYS 커맨드와 동일하게 조회 가능
    SCAN과 유사한 SSCAN, HSCAN, ZSCAN 커맨드 존재(SMEMBERS, HGETALL, ZRANGE WITHSCORE 대체)
      COUNT: 커서(페이지) 크기, 기본 10개(레디스 판단에 따라 좀더 효율적으로 1 ~ 2개 키를 더 읽어 반환하기도 함)
      MATCH: 패턴 비교(한번에 모든 결과를 반환하지 않고 커서 안에 결과를 반환)
      TYPE: 지정한 타입의 키만 조회(한번에 모든 결과를 반환하지 않고 커서 안에 결과를 반환)
    
  4. SORT

      SORT key [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] 
      [ASC|DESC] [ALPHA] [STORE destination]

    list, set, sorted set과 같이 순서가 존재하는 자료구조에서만 사용 가능
    키 내부의 아이템을 정렬해서 반환
      LIMIT: 일부 데이터만 조회 가능
      ALPHA: 데이터를 사전 순으로 정렬
      BY, GET: 정렬한 결과를 이용해 다른 키에 접근해서 데이터 조회 가능

  5. RENAME/RENAMENX

      RENAME key newkey
      RENAMENX key newkey

    키의 이름을 변경하는 커맨드
    RENAME 커맨드는 변경할 키가 이미 존재하면 덮어씌움(기존 키의 값은 사라짐)
    RENAMENX 커맨드는 오직 변경할 키가 존재하지 않을 때에만 동작

  6. COPY

      COPY source destination [DB destination-db] [REPLACE]

    source에 지정된 키를 destination에 복사
    destination에 지정한 키가 이미 있는 경우 에러가 반환
      REPLACE: destination 키 삭제 후 값 복사

  7. TYPE

      TYPE key

    지정한 키의 자료 구조 타입을 반환

  8. OBJECT

      OBJECT <subcommand> [<arg> [value] [opt] ...]
  
    키에 대한 상세 정보 반환
      subcommand: ENCODING, IDLETIME 등 해당 키가 내부적으로 어떻게 저장됐는지, 호출되지 않는 시간 등 조회


//키 삭제
  1. FLUSHALL

      FLUSHALL [ASYNC|SYNC]

    레디스에 저장된 모든 키를 삭제
    lazyfree-lazy-user-flush 옵션이 yes인 경우 ASYNC 옵션 없이도 ASYNC로 동작
      SYNC: 동기적 방식으로 모든 데이터가 삭제된 경우에만 OK, 해당 커맨드 실행 중 다른 응답 처리 불가
      ASYNC: flush를 백그라운드로 실행, 커맨드 수행됐을 때 존재했던 키만 삭제, flush 중에 생성된 키는 존재

    2. DEL
      
        DEL key [key ...]

      키와 키에 저장된 모든 아이템을 삭제
      기본적으로 동기적으로 동작
      하나의 키에 하나의 아이템만 저장된 자료구조에 사용
      lazyfree-lazy-user-del 옵션이 yes인 경우 모든 DEL 커맨드는 UNLINK로 동작

    3. UNLINK

        UNLINK key [key ...]

      DEL과 유사하게 키와 데이터를 삭제
      백그라운드에서 다른 스레드에 의해 처리되며 우선 키와 연결된 데이터의 연결을 끊음
      하나의 키에 여러 아이템이 저장된 자료구조에 사용
      

//키 만료시간
  1. EXPIRE
    
      EXPIRE key seconds [NX|XX|GT|LT]

    키가 만료될 시간을 초 단위로 정의
      NX: 해당 키에 만료시간이 정의돼 있지 않을 경우에만 커맨드 수행
      XX: 해당 키에 만료시간이 정의돼 있을 때에만 커맨드 수행
      GT: 현재 키가 가지고 있는 만료시간보다 새로 입력한 초가 더 클때에만 수행
      LT: 현재 키가 가지고 있는 만료시간보다 새로 입력한 초가 더 작을때에만 수행

  2. EXPIRETIME

      EXPIRETIME key

    키가 삭제되는 유닉스 타임스탬프를 초 단위로 반환
    키가 존재하지만 만료시간이 설정되지 않은 경우 -1, 키가 없는 경우 -2 반환

  3. EXPIREAT

      EXPIREAT key unix-time-seconds [NX|XX|GT|LT]

    키가 특정 유닉스 타임스탬프에 만료될 수 있도록 키의 만료시간을 직접 지정

  4. TTL

      TTL key

    키가 몇 초 뒤에 만료되는지 반환
    키가 존재하지만 만료시간이 설정되지 않은 경우 -1, 키가 없는 경우 -2 반환

  5. PEXPIRE, PREXPIREAT, EXPIRETIME, PTTL
    밀리초 단위로 계산된다는 점만 다르며 위의 커맨드와 동일


