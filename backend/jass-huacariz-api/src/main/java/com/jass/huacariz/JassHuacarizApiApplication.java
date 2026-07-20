package com.jass.huacariz;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class JassHuacarizApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(JassHuacarizApiApplication.class, args);
    }
}