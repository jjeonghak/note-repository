## 버전에 맞게 

````java
//querydsl 추가
buildscript {
	dependencies {
		classpath("gradle.plugin.com.ewerk.gradle.plugins:querydsl-plugin:1.0.10")
	}
}

plugins {
	id 'org.springframework.boot' version '2.7.0'
	id 'io.spring.dependency-management' version '1.0.11.RELEASE'
	id 'java'
}

//apply plugin: 'io.spring.dependency-management'
apply plugin: "com.ewerk.gradle.plugins.querydsl"

group = 'jpabook'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = '11'

configurations {
	compileOnly {
		extendsFrom annotationProcessor
	}
}

repositories {
	mavenCentral()
}

dependencies {
	implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
	implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
	implementation 'org.springframework.boot:spring-boot-starter-web'
	implementation 'org.springframework.boot:spring-boot-devtools'
	implementation 'org.springframework.boot:spring-boot-starter-validation'
	implementation 'com.fasterxml.jackson.datatype:jackson-datatype-hibernate5'

	implementation 'junit:junit:4.13.1'
	implementation 'com.github.gavlyukovskiy:p6spy-spring-boot-starter:1.8.0'

	compileOnly 'org.projectlombok:lombok'
	runtimeOnly 'com.h2database:h2'
	annotationProcessor 'org.projectlombok:lombok'
	testImplementation 'org.springframework.boot:spring-boot-starter-test'

	//querydsl 추가
	implementation 'com.querydsl:querydsl-jpa'
	implementation 'com.querydsl:querydsl-apt'
}

tasks.named('test') {
	useJUnitPlatform()
}
````

<br>

### querydsl 추가
````java
//def querydslDir = 'src/main/generated'
def querydslDir = "$buildDir/generated/querydsl"

querydsl {
	library = "com.querydsl:querydsl-apt"
	jpa = true
	querydslSourcesDir = querydslDir
}

sourceSets {
	main {
		java {
			srcDirs = ['src/main/java', querydslDir]
		}
	}
}

compileQuerydsl{
	options.annotationProcessorPath = configurations.querydsl
}

configurations {
	querydsl.extendsFrom compileClasspath
}
````

<br>
