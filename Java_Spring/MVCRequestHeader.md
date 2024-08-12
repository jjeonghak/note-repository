## header info
파라미터를 통해 여러 정보를 쉽게 접근 가능

````java
@RequestMapping("/headers")
public String headers(HttpServletRequest request,
                      HttpServletResponse response,
                      HttpMethod httpMethod,
                      Locale locale,
                      @RequestHeader MultiValueMap<String, String> headerMap,
                      @RequestHeader("host") String host,
                      @CookieValue(value = "cookie", required = false) String cookie) {

    log.info("request={}", request);
    log.info("response={}", response);
    log.info("httpMethod={}", httpMethod);
    log.info("locale={}", locale);
    log.info("headerMap={}", headerMap);
    log.info("host={}", host);
    log.info("cookie={}", cookie);

    return "ok";
}
````

<br>
    
## MultiValueMap
Map과 유사하지만 하나의 키에 여러 값 입력 가능  
Http header, Http 쿼리 파라미터와 같이 하나의 키에 여러값 받을때 사용  

<br>
