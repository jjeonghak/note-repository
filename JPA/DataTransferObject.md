## DTO(date transfer object)
계층간 데이터 교환이 이루어질 수 있도록 하는 객체(Java Beans)

````java
@PostMapping("/api/v2/members")
public CreateMemberResponse saveMemberV2(@RequestBody @Valid CreateMemberDTO request) {
    Member member = new Member();
    member.setName(request.getName());

    Long id = memberService.join(member);
    return new CreateMemberResponse(id);
}

@Data
static class CreateMemberDTO {
    @NotEmpty
    private String name;
}
````

<br>

### 엔티티를 직접 사용하는 것 지양
엔티티에 프레젠테이션 계층을 위한 로직 추가(@NotEmpty, @JsonIgnore 등)  
기본적으로 엔티티의 모든 속성값 노출  
API마다 필수 요소들이 상이하므로 각각 제한  
엔티티에 API 검증을 위한 로직 추가  
엔티티 변경시 API 스펙 또한 변경  

````java
@PostMapping("/api/v1/members")
public CreateMemberResponse saveMemberV1(@RequestBody @Valid Member member) {
    Long id = memberService.join(member);
    return new CreateMemberResponse(id);
}
````

<br>

