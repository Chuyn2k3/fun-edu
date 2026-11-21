package com.ibme.funedu.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/** FunEdu backend: family accounts, progress sync and online race rooms. */
@SpringBootApplication
@ConfigurationPropertiesScan
public class FunEduServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(FunEduServerApplication.class, args);
    }
}
