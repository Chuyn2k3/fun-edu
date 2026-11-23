package com.ibme.funedu.server.room;

import com.ibme.funedu.server.lobby.LobbySocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration(proxyBeanMethods = false)
@EnableWebSocket
@EnableScheduling
public class WebSocketConfig implements WebSocketConfigurer {

    private final RoomSocketHandler roomHandler;
    private final LobbySocketHandler lobbyHandler;

    public WebSocketConfig(RoomSocketHandler roomHandler, LobbySocketHandler lobbyHandler) {
        this.roomHandler = roomHandler;
        this.lobbyHandler = lobbyHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // The app is not a browser: auth is the bearer token, not cookies,
        // so the Origin header does not matter.
        registry.addHandler(roomHandler, "/ws/room").setAllowedOrigins("*");
        registry.addHandler(lobbyHandler, "/ws/lobby").setAllowedOrigins("*");
    }
}
