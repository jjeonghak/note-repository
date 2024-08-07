## 스프링 파일 업로드
서블릿과 다르게 @RequestParam, @ModelAttribute 어노테이션으로 file 데이터 받음  

````java
@Value("${file.dir}")
private String fileDir;

@PostMapping("/upload")
public String saveFile(@RequestParam String itemName, @RequestParam MultipartFile file,
                       HttpServletRequest request) throws IOException {
    log.info("request={}", request);
    log.info("itemName={}", itemName);
    log.info("multipartFile={]" , file);

    if (!file.isEmpty()) {
        String fullPath = fileDir + file.getOriginalFilename();
        log.info("save file fullPath={]", fullPath);
        file.transferTo(new File(fullPath));
    }
    return "upload-form";
}
````

````
file.getOriginalFilename() : 업로드 파일명
file.transferTo(...) : 파일 저장
````

<br>

## MultipartFile
고객이 업로드한 파일명과 서버 내부에서 저장한 파일명이 같으면 파일들끼리의 충돌발생  

    uploadFileName : 고객이 업로드한 파일명
    storeFileName : 서버 내부에서 관리하는 파일명

````html
<form th:action method="post" enctype="multipart/form-data">
    <ul>
        <li>상품명 <input type="text" name="itemName"></li>
        <li>첨부파일 <input type="file" name="file"></li>
        <li>이미지 파일 <input type="file" multiple="multiple" name="imageFiles"></li>
    </ul>
    <input type="submit"/>
</form>
````

````java
@Component
public class FileStore {

    @Value("${file.dir}")
    private String fileDir;

    public String getFullPath(String fileName) {
        return fileDir + fileName;
    }

    public UploadFile storeFile(MultipartFile multipartFile) throws IOException {
        if (multipartFile.isEmpty())
            return null;
        String originalFilename = multipartFile.getOriginalFilename();
        String storeFileName = createStoreFileName(originalFilename);
        multipartFile.transferTo(new File(getFullPath(storeFileName)));
        return new UploadFile(originalFilename, storeFileName);
    }

    //확장자를 포함한 storeFileName 반환
    private String createStoreFileName(String originalFilename) {
        String ext = extractExt(originalFilename);
        String uuid = UUID.randomUUID().toString();
        return uuid + '.' + ext;
    }

    //확장자 반환
    private String extractExt(String originalFilename) {
        int pos = originalFilename.lastIndexOf(".");
        return originalFilename.substring(pos + 1);
    }

    public List<UploadFile> storeFiles(List<MultipartFile> multipartFileList) throws IOException {
        List<UploadFile> storeFileResult = new ArrayList<>();
        for (MultipartFile multipartFile : multipartFileList) {
            if (!multipartFile.isEmpty()) {
                storeFileResult.add(storeFile(multipartFile));
            }
        }
        return storeFileResult;
    }
}
````

````java
@Slf4j
@Controller
@RequiredArgsConstructor
public class ItemController {

    private final ItemRepository itemRepository;
    private final FileStore fileStore;

    @GetMapping("/items/new")
    public String newItem(@ModelAttribute ItemForm form) {
        return "item-form";
    }

    @PostMapping("/items/new")
    public String saveItem(@ModelAttribute ItemForm form,
                           RedirectAttributes redirectAttributes) throws IOException {
        UploadFile attachFile = fileStore.storeFile(form.getAttachFile());
        List<UploadFile> storeImageFiles = fileStore.storeFiles(form.getImageFiles());

        Item item = new Item();
        item.setItemName(form.getItemName());
        item.setAttachFile(attachFile);
        item.setImageFiles(storeImageFiles);
        itemRepository.save(item);

        redirectAttributes.addAttribute("itemId", item.getId());
        return "redirect:/items/{itemId}";
    }

    @ResponseBody
    @GetMapping("/images/{filename}")
    public Resource downloadImage(@PathVariable String filename) throws MalformedURLException {
        return new UrlResource("file:" + fileStore.getFullPath(filename));
    }
    
    @GetMapping("/attach/{itemId}")
    public ResponseEntity<Resource> downloadAttach(@PathVariable Long itemId) throws MalformedURLException {
        Item item = itemRepository.findById(itemId);
        String storeFileName = item.getAttachFile().getStoreFileName();
        String uploadFileName = item.getAttachFile().getUploadFileName();
        UrlResource resource = new UrlResource("file:" + fileStore.getFullPath(storeFileName));
        log.info("uploadFileName={}", uploadFileName);
        //인코딩 및 첨부파일 다운을 위한 헤더 처리
        String encodedUploadFileName = UriUtils.encode(uploadFileName, StandardCharsets.UTF_8);
        String contentDisposition = "attachment; filename=\"" + encodedUploadFileName +"\"";
        return ResponseEntity.ok()
                //헤더가 없는 경우 다운로드가 아닌 화면출력만 가능
                .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition)
                .body(resource);
    }
}
````

<br>
