## 도메인 모델
도메인 객체의 API를 직접 이용하는 것보다 DSL을 이용하는 것이 효과적  

````java
public class Stock {
    private String symbol;
    private String market;
    
    //getter, setter
    ...
}

public class Trade {
    public enum Type { BUY, SELL }
    private Type type;
    private Stock stock;
    private int quantity;
    private double price;
    
    public double getValue() {
        return quantity * price;
    }
    
    //getter, setter
    ...
}

public class Order {
    private String customer;
    private List<Trade> trades = new ArrayList<>();
    
    public void addTrade(Trade trade) {
        this.trades.add(trade);
    }
    
    public double getValue() {
        return trades.stream().mapToDouble(Trade::getValue).sum();
    }
    
    //getter, setter
    ...
}
````

<br>

## method chain
메서드 호출 체인을 이용해서 DSL 생성 가능  
빌더가 끝날 때까지 다른 거래를 플루언트 방식으로 추가 가능  
여러 빌드 클래스를 따로 만들어서 미리 지정된 절차에 따라 플루언트 API의 메서드를 호출하도록 강제  
빌더를 구현해해야한다는 단점  

````java
Order order = forCustomer("BigBank")
    .buy(80)
    .stock("IBM")
    .on("NYSE")
    .at(125.00)
    .sell(50)
    .stock("GOOGLE")
    .on("NASDAQ")
    .at(375.00)
    .end();

//메서드 체인 DSL 제공하는 주문 빌더
public class MethodChainingOrderBuilder {
    public final Order order = new Order();
    
    private MethodChainingOrderBuilder(String customer) {
        order.setCustomer(customer);
    }
    
    public static MethodChainingOrderbuilder forCustomer(String customer) {
        return new MethodChainingOrderbuilder(customer);
    }
    
    public TradeBuilder buy(int quantity) {
        return new TradeBuilder(this, Trade.Type.BUY, quantity);
    }
    
    public TradeBuilder sell(int quantity) {
        return new TradeBuilder(this, Trade.Type.SELL, quantity);
    }
    
    public MethodChainingOrderBuilder addTrade(Trade trade) {
        order.addTrade(trade);
        return this;
    }
    
    public Order end() {
        return order;
    }
}

public class TradeBuilder {
    private final MethodChainingOrderBuilder builder;
    public final Trade trade = new Trade();
    
    private TradeBuilder(MethodChainingOrderBuilder builder, Trade.Type type, int quantity) {
        this.builder = builder;
        trade.setType(type);
        trade.setQuantity(quantity);
    }
    
    public StockBuilder stock(String symbol) {
        return new StockBuilder(builder, trade, symbol);
    }
}

public class StockBuilder {
    private final MethodChainingOrderBuilder builder;
    private final Trade trade;
    private final Stock stock = new Stock();
    
    private StockBuilder(MethodChainingOrderBuilder builder, Trade trade, String symbol) {
        this.builder = builder;
        this.trade = trade;
        stock.setSymbol(symbol);
    }
    
    public TradeBuilderWithStock on(String market) {
        stock.setMarket(market);
        trade.setStock(stock);
        return new TradeBuilderWithStock(builder, trade);
    }
}

public class TradeBuilderWithStock() {
    private final MethodChainingOrderBuilder builder;
    private final Trade trade;
    
    public TradeBuilderWithStock(MethodChainingOrderBuilder builder, Trade trade) {
        this.builder = builder;
        this.trade = trade;
    }
    
    public MethodChainingOrderBuilder at(double price) {
        trade.setPrice(price);
        return builder.addTrade(trade);
    }
}
````

<br>

## 중첩된 함수 이용
다른 함수 안에 함수를 이용해 도메인 모델을 생성  
메서드 체인에 비해 함수의 중첩 방식이 도메인 객체 계층 구조와 유사  
인수 목록을 정적 메서드에 넘겨야하므로 선택 사항 필드에 대해서 여러 오버라이드 구현 필수  

````java
Order order = order("BigBank",
    buy(80, stock("IBM", on("NYSE")), at(125.00)),
    sell(50, stock("GOOGLE", on("NASDAQ")), at(375.00)));

//중첩된 함수 DSL 제공하는 빌더
public class NestedFunctionOrderBuilder {
    public static Order order(String customer, Trade... trades) {
        Order order = new Order();
        order.setCustomer(customer);
        Stream.of(trades).forEach(order::addTrade);
        return order;
    }
    
    public static Trade buy(int quantity, Stock stock, double price) {
        return builderTrade(quantity, stock, price, Trade.Type.BUY);
    }
    
    public static Trade sell(int quantity, Stock stock, double price) {
        return builderTrade(quantity, stock, price, Trade.Type.SELL);
    }
    
    private static Trade buildTrade(int quantity, Stock stock, double price, Trade.Type type) {
        Trade trade = new Trade();
        trade.setQuantity(quantity);
        trade.setType(type);
        trade.setStock(stock);
        trade.setPrice(price);
        return trade;
    }
    
    public static double at(double price) {
        return price;
    }
    
    public static Stock stock(String symbol, String market) {
        Stock stock = new Stock();
        stock.setSymbol(symbol);
        stock.setMarket(market);
        return stock;
    }
    
    public static String on(String market) {
        return market;
    }
}
````

<br>

## 람다 표현식을 이용한 함수 시퀀싱
람다 표현식으로 정의한 함수 시퀀스를 사용하는 DSL  
이전 두가지 DSL 형식의 장점을 포함  
메서드 체인처럼 플루언트 방식과 중첩 함수 형식의 다양한 람다 표현식의 중첩 수준을 유지  

````java
Order order = order(o -> {
    o.forCustomer("BigBank");
    o.buy(t -> {
        t.quantity(80);
        t.price(125.00);
        t.stock(s -> {
            s.symbol("IBM");
            s.market("NYSE");
        });
    });
    o.sell(t -> {
        t.quantity(50);
        t.price(375.00);
        t.stock(s -> {
            s.symbol("GOOGLE");
            s.market("NASDAQ");
        });
    });
});

//함수 시퀀싱 DSL 제공하는 주문 빌더
public class LambdaOrderBuilder {
    private Order order = new Order();
    
    public static Order order(Consumer<LambdaOrderBuilder> consumer) {
        LambdaOrderBuilder builder = new LambdaOrderBuilder();
        consumer.accept(builder);
        return builder.order;
    }
    
    public void forCustomer(String customer) {
        order.setCustomer(customer);
    }
    
    public void buy(Consumer<TradeBuilder> consumer) {
        trade(consumer, Trade.Type.BUY);
    }
    
    public void sell(Consumer<TradeBuilder> consumer) {
        trade(consumer, Trade.Type.SELL);
    }
    
    private void trade(Consumer<TradeBuilder> consumer, Trade.Type type) {
        TradeBuilder builder = new TradeBuilder();
        builder.trade.setType(type);
        consumer.accept(builder);
        order.addTrade(builder.trade);
    }
}

public class TradeBuilder {
    private Trade trade = new Trade();
    
    public void quantity(int quantity) {
        trade.setQuantity(quantity);
    }
    
    public void price(double price) {
        trade.setPrice(price);
    }
    
    public void stock(Consumer<StockBuilder> consumer) {
        StockBuilder builder = new StockBuilder();
        consumer.accept(builder);
        trade.setStock(builder.stock);
    }
}

public class StockBuilder {
    private Stock stock = new Stock();
    
    public void symbol(String symbol) {
        stock.setSymbol(symbol);
    }
    
    public void market(String market) {
        stock.setMarket(market);
    }
}
````

<br>

## 조합하기
한 DSL에 한 개의 패턴만 사용할 필요는 없음  

````java
Order order = forCustomer("BigBank", 
    buy(t -> t.quantity(80)
        .stock("IBM")
        .on("NYSE")
        .at(125.00)),
    sell(t -> t.quantity(50)
        .stock("GOOGLE")
        .on("NASDAQ")
        .at(125.00)));

//여러 형식을 혼합한 DSL을 제공하는 주문 빌더
public class MixedBuilder {
    public static Order forCustomer(String customer, TradeBuilder... builders) {
        Order order = new Order();
        order.setCustomer(customer);
        Stream.of(builders).forEach(b -> order.addTrade(b.trade));
        return order;
    }
    
    public static TradeBuilder buy(Consumer<TradeBuilder> consumer) {
        return buildTrade(consumer, Trade.Type.BUY);
    }
    
    public static TradeBuilder sell(Consumer<TradeBuilder> consumer) {
        return buildTrade(consumer, Trade.Type.SELL);
    }
    
    private static TradeBuilder buildTrade(Consumer<TradeBuilder> consumber, Trade.Type type) {
        TradeBuilder builder = new TradeBuilder();
        builder.trade.setType(type);
        consumer.accept(builder);
        return builder;
    }
}

public class TradeBuilder {
    private Trade trade = new Trade();
    
    public TradeBuilder quantity(int quantity) {
        trade.setQuantity(quantity);
        return this;
    }
    
    public TradeBuilder at(double price) {
        trade.setPrice(price);
        return this;
    }
    
    public StockBuilder stock(String symbol) {
        return new StockBuilder(this, trade, symbol);
    }
}

public class StockBuilder {
    private final Tradebuilder builder;
    private final Trade trade;
    private final Stock stock = new Stock();
    
    private StockBuilder(TradeBuilder builder, Trade trade, String symbol) {
        this.builder = builder;
        this.trade = trade;
        stock.setSymbol(symbol);
    }
    
    public TradeBuilder on(String market) {
        stock.setMarket(market);
        trade.setStock(stock);
        return builder;
    }
}
````

<br>

