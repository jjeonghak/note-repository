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

