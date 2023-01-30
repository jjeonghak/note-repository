//make 파일관리유틸리티
//각 파일의 종속관계를 파악해 기술파일(makefile)에 기술된 대로 컴파일 명령이나 쉘 명령을 순차적으로 수행
//각 파일에 대한 반복적 명령 자동화
//컴파일 명령 시행 목적은 쉘 스크립트와 유사하지만, makefile은 하나의 소스파일 컴파일 가능하고 쉘 스크립트는 전체 컴파일만 가능
//쉘 스크립트는 위에서부터 순차적으로 명령어가 시행, makefile은 순서에 상관없이 시행


//구성요소
target1 : dependency1 dependency2
          command1
          command2

target2 : dependency3 dependency4
          command3
          command4


target : 미리 기술되어 있는 일련의 과정에 대응되는 것
         make 실행을 위해 make[target]과 같이 쉘에 입력

command(실행명령어) : target을 make 실행할때 실제로 시행되는 명령어들의 집합
                   반드시 tab을 이용한 들여쓰기 필수

dependency(의존파일) : 실행명령어들이 건드리는 파일들의 집합


//작동방식
foo: foo.c foo.h
          gcc -c -Wall -Wextra -Werror foo.c
          //c옵션 : 링크를 하지 않고 컴파일만 실행, main.c 없이 파일을 컴파일할 때 사용 

main.o: main.c foo.h
          gcc -c -Wall -Wextra -Werror main.c

pros: main.o foo.o
          gcc -Wall -Wextra -Werror main.o foo.o -o pros.exe
          //o옵션 : 내부적으로 링커를 싱행해서 실행파일 생성


 1. make pros 입력시
  1)pros 명령 시행을 위해 main.o, foo.o 필요
  2) main.o, foo.o 타겟 탐색
  3) 목적파일 타겟을 시행하기 위해 소스코드파일 필요
  4) 소스코드파일 존재 확인 후 명령어 실행(목적파일 컴파일)
  5) pros 의존파일 모두 생성 확인 후 실행파일(pros.exe) 컴파일

 2. foo.c 변경후, make pros 재입력
  1)pros 명령 시행을 위해 main.o, foo.o 필요
  2) main.o, foo.o 타겟 탐색
  3) foo의 목적파일의 생성시간이 소스코드파일 수정시간보다 이전이므로 foo.o 타겟 시행
  4) pros 의존파일 모두 생성 확인 후 실행파일(pros.exe) 컴파일


//변수
= 변수 정의시 다른 변수가 포함되어 있다면 그 변수가 정의되기까지 변수값 보류(순서 영향 없음)
:= 변수 정의시 다른 변수가 포함되어 있다면 해당 명령어가 실행될 때의 변수값(순서 영향)

CC = gcc
CFLAG = -Wall -Wextra -Werror

foo.o: foo.c foo.h
          $(CC) $(CFLAG) -c foo.c

main.o: main.c foo.h
          $(CC) $(CFLAG) -c main.c

pros: main.o foo.o
          $(CC) $(CFLAG) main.o foo.o -o pros.exe


//의존파일 없는 타겟
pros 시행시 pros.exe뿐만 아닌 여러 목적파일들도 작업 디렉토리에 생성되므로 이를 제거하는 명령어도 추가

OBJS = main.o foo.o

.PHONY: clean
//clean 파일의 유무와 상관없이 명령절 시행

clean:
          rm -f $(OBJS)
* 만약 디렉토리에 clean파일 존재시, clean 의존파일이 없고 최신상태이므로 명령절 시행무시


//패턴
//%는 *와 같은 효과
%.o: %.c %.h
          $(CC) $(CFALGS) -c $<
          * $@ : 타겟이름
            $< : 의존파일목록의 첫번째 파일
            $^ : 의존파일목록 전체
            $? : 타겟보다 최신인 의존파일들
            $+ : $^와 비슷, 중복된 파일 이름들까지 모두 포함


//자동 prerequiste 생성
컴파일 시 -MD 옵션을 추가하면 .d 파일이 생성됨
* .d파일 : makefile의 target: prerequisite 부분 생성, 즉 타겟과 그 의존파일 목록전체 기술

CC = gcc
CFLAGS = -Wall -Wextra -Werror
OBJS = main.o foo.o

%.o: %.c %.h
          $(CC) $(CFLAGS) -c $<
pros : $(OBJS)
          $(CC) $(CFLAGS) $(OBJS) -o pros.exe
.PHONY: clean
clean:
          rm -f $(OBJS) pros
include main.d 

또는

CC = gcc
CFLAGS = -Wall -Wextra -Werror
OBJS = main.o foo.o

%.o: %.c
          $(CC) $(CFLAGS) -c $<
pros : $(OBJS)
          $(CC) $(CFLAGS) $(OBJS) -o pros.exe
.PHONY: clean
clean:
          rm -f $(OBJS) pros
-include $(OBJS:.o=.d)
//.o인 부분을 .d로 변경, 같은 타겟에 대해서 여러 의존파일목록은 하나로 병합


//주요 문법
$(addsuffix 접미사, 문자열)
          $(addsuffix .c, main foo) => main.c foo.c
          
$(addprefix 접두어, 문자열)
          $(addprefix ./src/, main foo) => ./src/main ./src/foo

$(shell <shell-conmmand>)
          SH = $(shell ls *.c) => shell 명령에 대한 결과가 변수에 들어감

$(subst 탐색문자, 변경문자, 대상문자)
          "대상문자"에서 "탐색문자"를 "변경문자"로 변경

$(patsubst 탐색패턴, 변경패턴, 대상문자)
          subst와 유사하지만 주로 확장자 변경시 사용

$(strip 대상문자)
          대상문자에서 모든 공백을 1칸 줄인다.

$(filter 탐색문자, 대상문자)
          대상문자에서 탐색문자를 포함한 문자들을 찾아서 저장

$(filter-out 탐색문자, 대상문자)
          filter와 반대로 탐색문자가 있는 경우 제외하고 저장

$(join 원본문자, 추가문자)
          원본문자에 추가문자를 붙여서 한문자로

$(dir 대상문자)
          대상문자에서 파일문자를 제외한 경로만 추출

$(notdir 대상문자)
          대상문자에서 파일명만 추출

$(baseanme 대상문자)
          대상문자에서 확장자를 제외

