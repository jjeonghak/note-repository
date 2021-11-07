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
function.o: function.c
          gcc -c -Wall -Wextra -Werror function.c
          //c옵션 : 링크를 하지 않고 컴파일만 실행, main.c 없이 파일을 컴파일할 때 사용 

main.o: main.c
          gcc -c -Wall -Wextra -Werror main.c

pros: main.o function.o
          gcc -Wall -Wextra -Werror main.o funtion.o -o pros.exe
          //o옵션 : 내부적으로 링커를 싱행해서 실행파일 생성


 1. make pros 입력시
  1)pros 명령 시행을 위해 main.o, function.o 필요
  2) main.o, function.o 타겟 탐색
  3) 목적파일 타겟을 시행하기 위해 소스코드파일 필요
  4) 소스코드파일 존재 확인 후 명령어 실행(목적파일 컴파일)
  5) pros 의존파일 모두 생성 확인 후 실행파일(pros.exe) 컴파일

 2. function.c 변경후, make pros 재입력
  1)pros 명령 시행을 위해 main.o, function.o 필요
  2) main.o, function.o 타겟 탐색
  3) function의 목적파일의 생성시간이 소스코드파일 수정시간보다 이전이므로 function.o 타겟 시행
  4) pros 의존파일 모두 생성 확인 후 실행파일(pros.exe) 컴파일


//변수
CC = gcc
CFLAG = -Wall -Wextra -Werror

function.o: function.c
          $(CC) $(CFLAG) -c function.c

main.o: main.c
          $(CC) $(CFLAG) -c main.c

pros: main.o function.o
          $(CC) $(CFLAG) main.o funtion.o -o pros.exe


