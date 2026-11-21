package com.ibme.funedu.server;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.type.AnnotatedTypeMetadata;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * PostgreSQL for tests: a throwaway Testcontainers database, or the one in
 * TEST_DB_URL when that is set.
 */
@TestConfiguration(proxyBeanMethods = false)
public class TestDatabase {

    @Bean
    @ServiceConnection
    @Conditional(NoTestDbUrl.class)
    PostgreSQLContainer<?> postgres() {
        return new PostgreSQLContainer<>("postgres:16-alpine");
    }

    static class NoTestDbUrl implements org.springframework.context.annotation.Condition {
        @Override
        public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
            String url = System.getenv("TEST_DB_URL");
            return url == null || url.isBlank();
        }
    }
}
