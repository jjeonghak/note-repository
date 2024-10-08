## RestController
@Controller 어노테이션은 반환값이 String이면 뷰이름으로 인식, 뷰 탐색 후 랜더링  
@RestController 어노테이션은 반환값이 HTTP 메시지 바디  

<br>

## RequestMapping
@RequestMapping 어노테이션에 설정된 URL 호출시 메서드 실행  
배열을 이용해 다중 URL 설정 가능  
method 속성으로 HTTP 메서드 설정 가능(다른 메서드로 url 호출시 405, Method Not Allowed)  

````java
@RequestMapping({value = {"url1", "url2"}, method = RequestMethod.GET})
````

<br>

## PathVariable
경로 변수는 @PathVariale 어노테이션과 변수명이 같으면 생략가능  
다중 매핑도 가능  

````java
    @GetMapping("/mapping/{data}")
    public String pv(@PathVariable("data") String data) {  //@PathVarialbe String data
        log.info("pv data={}", data);
        return "ok";
    }
````

<br>

## 여러 조건 매핑
url 뿐만 아니라 파라미터 정보도 추가로 매핑(url 정보와 파라미터 정보 둘다 있어야 매핑)  
````java
//http://localhost:8080/mapping-param?mode=debug
@GetMapping(value = "/mapping-param", params = "mode=debug")
public String param() {
    log.info("mappingParam");
    return "ok";
}
````

url 뿐만 아니라 HTTP 헤더 정보도 추가로 매핑
````java
//header 정보에 {key:mode, value:debug} 추가 
@GetMapping(value = "/mapping-header", headers = "mode=debug")
public String headers() {
    log.info("mappingHeaders");
    return "ok";
}
````

url 뿐만 아니라 Content-Type 정보도 추가로 매핑
````java
@PostMapping(value = "/mapping-consumes", consumes = "application/json")
public String consumes() {
    log.info("mappingConsumes");
    return "ok";
}
````

url 뿐만 아니라 Accept 정보도 추가로 매핑(요청 정보와 맞지 않으면 406, Not Acceptable)
````java
@PostMapping(value = "/mapping-produce", produce = "text/html")
public String produces() {
    log.info("mappingProduces");
    return "ok";
}
````

<br>

