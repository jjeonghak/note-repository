## 로그인 상태유지
로그인 상태를 유지하기 위해 쿼리 파라미터를 계속 유지하면서 보내는 것은 번거로움  
서버에서 로그인에 성공하면 응답에 데이터베이스 아이디 정보를 쿠키에 담아서 브라우저에 전달  
브라우저는 해당 세션 쿠키를 지속해서 전달  

    [Request]
      POST/HTTP/1.1
      loginId=xxx&password=xxx
    
    [Response]
      HTTP/1.1 200 OK
      Set-Cookie: memberId=1
      ...
      login success
    
    [Request]
      GET/HTTP/1.1
      Cookie: memberId=1

<br>

## 쿠키 보안
쿠키에 중요한 값 노출금지(사용자 별로 예측이 불가능한 임의의 토큰 노출, 서버에서 토큰관리)  
토큰 만료시간을 짧게 설정, 해킹 의심되는 경우 해당 토큰 삭제  
  
1. 쿠키 값 임의 변경가능  
    클라이언트가 쿠키를 강제로 변경하면 다른 사용자가 된다
  
2. 쿠키에 보관된 정보 탈취가능  
    쿠키 내에 개인정보가 자체 로컬 pc 및 네트워크 전송구간에서 탈취가능
  
3. 한번 탈취한 쿠키는 영속적으로 사용가능  

<br>