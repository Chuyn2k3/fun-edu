package com.ibme.funedu.server.lobby;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/** Lobby WebSocket timings and connection limits. */
@ConfigurationProperties("funedu.lobby")
public record LobbyProperties(
        @DefaultValue("30s") Duration inviteTtl,
        @DefaultValue("60s") Duration idleTimeout,
        @DefaultValue("3") int maxConnectionsPerFamily,
        @DefaultValue("5") int maxMessagesPerSecond) {}
