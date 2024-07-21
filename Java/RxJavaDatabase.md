## 관계형 데이터베이스
Java에서 관계형 데이터베이스 접근을 위해 만든 표준 JDBC(java database connectivity)  
핵심 추상화는 Connection(TCP/IP, 회선연결), Statement(데이터베이스 질의), ResultSet(뷰를 통한 결과)  
JDBC API에 새로운 Connection 요구시 클라이언트 소켓을 열고 권한을 부여하는 등 물리적 연결 필요  
본질적으로 블로킹 방식이기에 개별 데이터베이스 작업이 완료될 때까지 대기  

````java
try (
    Connection con = DriverManager.getConnection("jdbc:h2:mem:");
    Statement stm = con.createStatement();
    ResultSet rs = stm.executeQuery("SELECT 2 + 2 AS total")
) {
    if (rs.next()) {
        System.out.println(rs.getInt(total));
        asset rs.getInt("total") == 4;
    }
}
````

<br>

## 데이터베이스 변환
JDBC를 여전히 블로킹 방식으로 유지하는 이유  
데이터베이스 시스템은 각 클라이언트 질의 시 몇 가지 단계를 수행  
publish().refCount() 메서드를 통해 하나의 연결 유지 가능  

1. 질의 구문 분석 : 질의를 포함하는 String을 구문 분석 트리로 변환(CPU 기반)  
2. 옵티마이저 : 다양한 규칙과 통계에 대한 질의 평가 및 실행 계획 수립(CPU 기반)  
3. 질의 실행기 : 데이터베이스 저장소 탐색 및 반환할 튜플 탐색(I/O 기반)  
4. 결과 집합 : 결과를 직렬화하여 반환(네트워크 기반)  

<br>

### PostgreSQL 완전한 블로킹
````java
try (Connection con = DriverManager.getConnection("jdbc:postgresql:db")) {
    try (Statement stm = con.createStatement()) {
        stm.execute("LISTEN my_channel");
    }
    Jdbc4Connection pgCon = (Jdbc4Connection) con;
    pollForNotifications(pgCon);
}

void pollForNotifications(Jdbc4Connection pgCon) throws Exception {
    while (!Thread.currentThread().isInterrupted()) {
        final PGNotification[] notifications = pgCon.getNotifications();
        if (notifications != null) {
            for (final PGNotification notification : notifications) {
                System.out.println(
                    notification.getName() + ": " +
                    notification.getParameter()
                );
            }
        }
        TimeUnit.MILLISECONDS.sleep(100);
    }
}
````

<br>

### Rx 친화적 변경
````java
Observable<PGNotification> observe(String channel, long pollingPeriod) {
    return Observable.<PGNotification>create(subscriber -> {
        try {
            Connection con = DriverManager.getConnection("jdbc:postgresql:db");
            subscriber.add(Subscriptions.create(() -> closeQuietly(con)));
            listenOn(con, channel);
            Jdbc4Connection pgCon = (Jdbc4Connection) con;
            pollForNotifications(pollingPeriod, pgCon).subscribe(Subscribers.wrap(subscriber));
        } catch (Exception e) {
            subscriber.onError(e);
        }
    }).share();
}

void listenOn(Connection con, String channel) throws SQLException {
    try (Statement stm = con.createStatement()) {
        stm.execute("LISTEN " + channel);
    }
}

void closeQuietly(Connection con) {
    try {
        con.close();
    } catch (SQLException e) {
        e.printStackTrace();
    }
}

Observable<PGNotification> pollForNotifications(
        long pollingPeriod, AbstractJdbc2Connection pgCon) {
    return Observable
        .interval(0, pollingPeriod, TimeUnit.MILLISECONDS)
        .flatMap(x -> tryGetNotification(pgCon))
        .filter(arr -> arr != null)
        .flatMapIterable(Arrays::asList);
}

Observable<PGNotification[]> tryGetNotification(AbstractJdbc2Connection pgCon) {
    try {
        return Observable.just(pgCon.getNotifications());
    } catch (SQLException e) {
        return Observable.error(e);
    }
}
````

<br>
