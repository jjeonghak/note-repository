## 포멧터
컨버터의 특별한 버전  
웹 애플리케이션의 대부분의 타입 캐스팅은 객체에서 문자로, 문자에서 객체로의 변환  
객체르르 특정한 포멧에 맞추어 문자로 출력하거나 그 반대의 기능을 제공  
현지화(locale) 기능 추가 제공  
필드의 타입이나 어노테이션 정보를 활용하려면 AnnotationFormatterFactory 사용  
기본적으로 컨버터보다 우선순위가 낮으므로 포멧터와 유사한 기능의 컨버터 주석처리  

````java
public interface Printer<T> {
    //객체를 문자로 변경
    String print(T object, Locale locale);
}

public interface Parser<T> {
    //문자를 객체로 변경
    T parse(String text, Locale locale) throws ParseException;
}

public interface Formatter<t> extends Printer<T>, Parser<T> {
    ...
}

@Slf4j
public class MyNumberFormatter implements Formatter<Number> {
    @Override
    public Number parse(String text, Locale locale) throws ParseException {
        log.info("text={}, locale={}", text, locale);
        NumberFormat format = NumberFormat.getInstance(locale);
        return format.parse(text);
    }

    @Override
    public String print(Number object, Locale locale) {
        log.info("object={}, locale={}", object, locale);
        NumberFormat instance = NumberFormat.getInstance(locale);
        return instance.format(object);
    }
}
````

<br>

## 포멧처 컨버전 서비스
기본적으로 ConversionService 상속으로 컨버터 또한 등록가능(포멧터 등록 기능 추가)  
FormattingConversionService : 포멧터를 지원하는 컨버젼 서비스  
DefaultFormattingConversionService : FormattingConversionService + 기본적인 통화, 숫자 관련 포멧터   

````java
public class FormattingConversionServiceTest {
    @Test
    void formattingConversionService() {
        DefaultFormattingConversionService cs = new DefaultFormattingConversionService();
        //컨버터 등록
        cs.addConverter(new StringToIpPortConverter());
        cs.addConverter(new IpPortToStringConverter());
        //포멧터 등록
        cs.addFormatter(new MyNumberFormatter());

        IpPort ipPort = cs.convert("127.0.0.1:8080", IpPort.class);
        Assertions.assertThat(ipPort).isEqualTo(new IpPort("127.0.0.1", 8080));
        //포멧터 사용(컨버터와 동일)
        Assertions.assertThat(cs.convert(1000L, String.class)).isEqualTo("1,000");
        Assertions.assertThat(cs.convert("1,000", Long.class)).isEqualTo(1000);
    }
}
````

<br>

## 스프링 기본 포멧터
많은 기본 포멧터들이 스프링에 등록  
때문에 객체의 각 필드마다 다른 형식으로 포멧 지정하기 어려움  
이러한 문제를 해결하기 위해 어노테이션 기반으로 형식 지정 기능 제공  

@NumberFormat : 숫자 관련 형식 지정 포멧터(NumberFormatAnnotationFormatterFactory)  
@DateTimeFormat : 날짜 관련 형식 지정 포멧터(Jsr310DateTimeFormatAnnotationFormatterFactory)  

````java
@NumberFormat(pattern = "###,###")
@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
````

<br>
