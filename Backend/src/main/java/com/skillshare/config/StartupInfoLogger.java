package com.skillshare.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
public class StartupInfoLogger implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(StartupInfoLogger.class);

    private final Environment environment;

    public StartupInfoLogger(Environment environment) {
        this.environment = environment;
    }

    @Override
    public void run(ApplicationArguments args) {
        String url = environment.getProperty("spring.datasource.url");
        String username = environment.getProperty("spring.datasource.username");

        log.info("Resolved spring.datasource.url={}", url);
        log.info("Resolved spring.datasource.username={}", username);
    }
}
