## 검증 로직 분리
컨트롤러에서 검증 로직이 차지하는 부분이 너무 크므로 클래스로 역할 분리

````java
public interface Validator {
    boolean supports(Class<?> clazz);
    void validate(Object target, Errors errors);
}

@Component
public class ItemValidator implements Validator {
    @Override
    public boolean supports(Class<?> clazz) {
        return Item.class.isAssignableFrom(clazz);
        //Item == clazz
        //Item == subItem
    }
    
    @Overrride
    public void validate(Object target, Errors errors) {
        Item item = (Item) target;
        BindingResult bindingResult = (BindingResult) errors;
        ...
    }
}
````

<br>

## WebDataBinder
스프링의 파라미터 바인딩 및 검증 기능  
컨트롤러가 호출될때마다 검증기 적용  
@Validated, @Valid 어노테이션을 통해 검증기 자동호출  
검증기 자동호출시 supports 함수를 통해 가장 적절한 검증기 호출  

````java
@InitBinder
public void init(WebDataBinder dataBinder) {
    dataBinder.addValidators(itemValidator);
}

@PostMapping("/add")
public String addItem(@Validated @ModelAttribute Item item, BindingResult bindingResult) {
    ...
}
````

<br>

## 글로벌 설정
모든 컨트롤러에서 적용  
글로벌 설정시 BeanValidator 자동 등록이 되지않음  

````java
@SpringBootApplication
public class ItemServiceApplication implements WebMvcConfigurer {
    
    public static void main(String[] args) {
        SpringApplication.run(ItemServiceApplication.class, args);
    }
    
    @Override
    public Validator getValidator() {
        return new ItemValidator();
    }
}
````

<br>
