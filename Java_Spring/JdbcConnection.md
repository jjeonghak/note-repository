## 데이터베이스 연결
접근 방식은 각 데이터베이스 별로 표준으로 정해져 있으므로 참고  
JDBC DriverManager를 통해 커넥션 구현체 반환  

````java
public abstract class ConnectionConst {
    public static final String URL = "jdbc:h2:tcp://localhost/~/jdbc";
    public static final String USERNAME = "sa";
    public static final String PASSWORD = "";
}

@Slf4j
public class DBConnectionUtil {
    public static Connection getConnection() {
        try {
            Connection connection = DriverManager.getConnection(ConnectionConst.URL,
                    ConnectionConst.USERNAME, ConnectionConst.PASSWORD);
            log.info("get connection={}, class={}", connection, connection.getClass());
            return connection;
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
````

<br>

## DriverManager
라이브러리에 등록된 DB 드라이버들을 관리하고 커넥션을 획득하는 기능 제공  
등록된 드라이버 목록을 순서대로 파라미터 정보(url, 사용자 정보)를 넘겨서 커넥션을 획득할 수 있는지 확인  
각각의 드라이버는 url 정보를 체크해서 본인이 처리할 수 있는 요청인지 확인  

<br>

## ResultSet
select 쿼리의 결과가 순서대로 들어있음  
내부에 존재하는 커서(cursor)를 이동해서 다음 데이터를 조회  
최초의 커서는 데이터를 가리키고 있지 않기 때문에 최소 한번은 rs.next() 호출  

````java
// 다음 데이터가 있는 경우 true 반환
rs.next();

// 현재 커서가 가리키고 있는 위치의 member_id 데이터를 문자로 반환
rs.getString("member_id");

// 현재 커서가 가리키고 있는 위치의 money 데이터를 정수로 반환
rs.getInt("money");
````

<br>
  
## JDBC repository  
````java
/*
 * JDBC - DriverManager 사용
 */
@Slf4j
public class MemberRepositoryV0 {

    public Member save(Member member) throws SQLException {
        String sql = "insert into member(member_id, money) values(?, ?)";

        Connection con = null;
        //PreparedStatement = Statement + 파라미터 바인딩
        PreparedStatement pstmt = null;

        try {
            con = getConnection();
            pstmt = con.prepareStatement(sql);
            //파라미터 바인딩(SQL Injection 방지)
            pstmt.setString(1, member.getMemberId());
            pstmt.setInt(2, member.getMoney());
            //Statement 통해 준비된 sql을 커넥션은 통해 실제 데이터베이스에 전달(영향받은 row 갯수 반환)
            pstmt.executeUpdate();
            return member;
        } catch (SQLException e) {
            log.error("db error", e);
            throw e;
        } finally {
            close(con, pstmt, null);
        }
    }

    public Member findById(String memberId) throws SQLException {
        String sql = "select * from member where member_id = ?";

        Connection con = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            con = getConnection();
            pstmt = con.prepareStatement(sql);
            pstmt.setString(1, memberId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                Member member = new Member();
                member.setMemberId(rs.getString("member_id"));
                member.setMoney(rs.getInt("money"));
                return member;
            } else {
                throw new NoSuchElementException("member not found memberId=" + memberId);
            }
        } catch (SQLException e) {
            log.info("db error", e);
            throw e;
        } finally {
            close(con, pstmt, rs);
        }
    }
    
    public void update(String memberId, int money) throws SQLException {
        String sql = "update member set money = ? where member_id = ?";

        Connection con = null;
        PreparedStatement pstmt = null;

        try {
            con = getConnection();
            pstmt = con.prepareStatement(sql);
            pstmt.setInt(1, money);
            pstmt.setString(2, memberId);
            int resultSize = pstmt.executeUpdate();
            log.info("resultSize={}", resultSize);
        } catch (SQLException e) {
            log.error("db error", e);
            throw e;
        }
    }
    
    public void delete(String memberId) throws SQLException {
        String sql = "delete from member where member_id = ?";

        Connection con = null;
        PreparedStatement pstmt = null;

        try {
            con = getConnection();
            pstmt = con.prepareStatement(sql);
            pstmt.setString(1, memberId);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            log.error("db error", e);
            throw e;
        }
    }

    private void close(Connection con, Statement stmt, ResultSet rs) {
        //예외 발생시 예외를 던지지 않고 다음 리소스 처리
        //지속되는 커넥션에 의한 리소스 누수 방지
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                log.info("ResultSet close error", e);
            }
        }
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                log.info("Statement close error", e);
            }
        }
        if (con != null) {
            try {
                con.close();
            } catch (SQLException e) {
                log.info("Connection close error", e);
            }
        }
    }

    private Connection getConnection() {
        return DBConnectionUtil.getConnection();
    }
}
````

<br>
