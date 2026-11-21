package com.ibme.funedu.server.room;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/** Race room timings and limits. */
@ConfigurationProperties("funedu.rooms")
public record RoomProperties(
        @DefaultValue("3s") Duration countdown,
        @DefaultValue("30m") Duration lobbyTtl,
        @DefaultValue("20s") Duration reconnectGrace,
        @DefaultValue("10m") Duration maxRaceTime,
        @DefaultValue("10m") Duration keepDone,
        @DefaultValue("600ms") Duration minStepInterval,
        @DefaultValue("4") int maxPlayers,
        @DefaultValue("20") int createsPerHour,
        @DefaultValue("10") int failedJoinsPerMinute) {}
