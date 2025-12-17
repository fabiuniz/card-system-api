package com.fabiano.cardsystem;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class })
public class CardSystemApplication {
    public static void main(String[] args) {
        SpringApplication.run(CardSystemApplication.class, args);
    }
}
