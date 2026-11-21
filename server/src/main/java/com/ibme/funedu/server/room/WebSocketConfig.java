package com.ibme.funedu.server.room;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration(proxyBeanMethods = false)
@EnableWebSocket
@EnableScheduling
public class WebSocketConfig implements WebSocketConfigurer {

    private final RoomSocketHandler handler;

    public WebSocketConfig(RoomSocketHandler handler) {
        this.handler = handler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // The app is not a browser: auth is the bearer token, not cookies,
        // so the Origin header does not matter.
        registry.addHandler(handler, "/ws/room").setAllowedOrigins("*");
    }
}
