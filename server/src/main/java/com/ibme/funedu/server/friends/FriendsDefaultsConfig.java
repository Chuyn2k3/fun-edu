package com.ibme.funedu.server.friends;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Provides no-op/offline fallbacks for lobby presence and notifications when
 * {@code LobbyRegistry} is not registered.
 */
@Configuration(proxyBeanMethods = false)
class FriendsDefaultsConfig {

    @Bean
    @ConditionalOnMissingBean(PresenceView.class)
    PresenceView offlinePresenceView() {
        return new PresenceView.Offline();
    }

    @Bean
    @ConditionalOnMissingBean(LobbyNotifier.class)
    LobbyNotifier noopLobbyNotifier() {
        return new LobbyNotifier.Noop();
    }
}
