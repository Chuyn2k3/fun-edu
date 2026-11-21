package com.ibme.funedu.server;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import(TestDatabase.class)
class ServerSkeletonTest {

    @Autowired
    TestRestTemplate http;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void healthIsUpWithoutDetails() {
        var res = http.getForEntity("/actuator/health", String.class);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(res.getBody()).contains("\"status\":\"UP\"")
                .doesNotContain("components")
                .doesNotContain("details");
    }

    @Test
    void readinessProbeIsUp() {
        var res = http.getForEntity("/actuator/health/readiness", String.class);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void otherActuatorEndpointsAreNotExposed() {
        assertThat(http.getForEntity("/actuator/env", String.class).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(http.getForEntity("/actuator/beans", String.class).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void migrationsCreateFamilyTablesWithUniqueGoogleSubject() {
        UUID family = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", family);
        String subject = "google-sub-" + UUID.randomUUID();
        jdbc.update("INSERT INTO parent_accounts (id, family_id, provider, subject) VALUES (?, ?, 'google', ?)",
                UUID.randomUUID(), family, subject);

        assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO parent_accounts (id, family_id, provider, subject) VALUES (?, ?, 'google', ?)",
                UUID.randomUUID(), family, subject))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO parent_accounts (id, family_id, provider, subject) VALUES (?, ?, 'apple', ?)",
                UUID.randomUUID(), family, "x"))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void deletingAFamilyDeletesItsParentAccounts() {
        UUID family = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", family);
        jdbc.update("INSERT INTO parent_accounts (id, family_id, provider, subject) VALUES (?, ?, 'google', ?)",
                UUID.randomUUID(), family, "sub-" + family);
        jdbc.update("DELETE FROM families WHERE id = ?", family);
        Integer left = jdbc.queryForObject(
                "SELECT count(*) FROM parent_accounts WHERE family_id = ?", Integer.class, family);
        assertThat(left).isZero();
    }
}
