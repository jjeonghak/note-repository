/* 하이라이트 */
if has("syntax")
	syntax on
endif

/* 검색할 때 매칭되는 문자열 하이라이트 */
set hlsearch

/* 라인 넘버 */
set nu

/* 자동 들여쓰기 */
set autoindent
set cindent

/* tap space 설정 */
set ts=4  	 //문서의 '\t' 스페이스 갯수 설정
set sts= 4	 //tab키를 눌렀을때 스페이스 갯수 설정
set shiftwidth=4 //자동 들여쓰기 할때 스페이스 갯수 설정

/* status */
set laststatus=2 //0-출력안함, 1-창이 2개이상일때 출력, 2-항상출력

/* 괄호 짝 하이라이트 */
set showmatch

/* smart setting */
set smartcase	 //no automatic ignore case switch
set smarttab	 //ts, sts, sw 값 참조하여 동작 보조
set smartindent  //전처리 구문 판단하여 들여쓰기

/* 커서 위치 */
set ruler

/* encoding */
set fileencodings=utf8,euc-kr  //window(euc-kr), linux(utf8) 인코딩 방식이 달라도 정상출력


