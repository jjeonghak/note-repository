## 큐컴버
다른 동작 주도 개발(BDD) 프레임워크와 마찬가지로 명령문을 실행할 수 있는 테스트임  
동시에 비즈니스 기능의 수용 기준  
외부적 DSL과 내부적 DSL이 효과적으로   


````java
//큐컴버 스크립팅 언어로 간단한 비즈니스 시나이오
Feature: Buy stock
  Scenario: Buy 10 IBM stocks
    Given the price of a "IBM" stock is 125$
    When I buy 10 "IBM"
    Then the order value should be 1250$
````

<br>

## 큐컴버 개념
1. 전제 조건 정의(Given) : 테스트를 위해 주어진 상황 및 조건  
2. 도메인 실질 호출(When) : 테스트하려는 실제 도메인 객체 호출  
3. 어설션(Then) : 테스크 케이스의 결과를 확인  

<br>

## 테스트 시나리오
스크립트는 제한된 수의 키워드를 제공  
자유로운 형식으로 문장을 구현할 수 있는 외부 DSL 활용  
이 문장은 변수를 캡처하는 정규 표현식으로 매칭  
테스트 자체를 구현하는 메서드로 전달  

````java
//큐컴버 어노테이션을 이용한 테스트 시나리오
public class BuyStockSteps {
    private Map<String, Integer> stockUnitPrices = new HashMap<>();
    private Order order = new Order();
    
    @Given("^the price of a \"(.*?)\" stock is (\\d+)\\$$")
    public void setUnitPrice(String stockName, int unitPrice) {
        stockUnitValues.put(stockName, unitPrice);
    }
    
    @When("^I buy (\\d+) \"(.*?)\"$")
    public void buyStocks(int quantity, String stockName) {
        Trade trade = new Trade();
        trade.setType(Trade.Type.BUY);
        
        Stock stock = new Stock();
        stock.setSymbol(stockName);
        
        trade.setStock(stock);
        trade.setPrice(stockUnitPrices.get(stockName));
        trade.setQuantity(quantity);
        order.addTrade(trade);
    }
    
    @Then("^the order value should be (\\d+)\\$$")
    public void checkOrderValue(int expectedValue) {
        assertEquals(expectedValue, order.getValue());
    }
}

//람다 형식
public class BuyStocksSteps implements cucumber.api.java8.En {
    private Map<String, Integer> stockUnitPrices = new HashMap<>();
    private Order order = new Order();
    
    public BuyStocksSteps() {
        Given("^the price of a \"(.*?)\" stock is (\\d+)\\$$",
            (String stockName, int unitPrice) -> {
                stockUnitValues.put(stockName, unitPrice);
        });
        When("^I buy (\\d+) \"(.*?)\"$",
            (int quantity, String stockName) -> {
                Trade trade = new Trade();
                trade.setType(Trade.Type.BUY);

                Stock stock = new Stock();
                stock.setSymbol(stockName);

                trade.setStock(stock);
                trade.setPrice(stockUnitPrices.get(stockName));
                trade.setQuantity(quantity);
                order.addTrade(trade);
        });
        Then("^the order value should be (\\d+)\\$$",
            (int expectedValue) -> {
                assertEquals(expectedValue, order.getValue());
        });
    }
}

````

<br>
