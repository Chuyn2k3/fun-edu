package com.ibme.funedu.server.friends;

import java.util.Map;
import java.util.UUID;

/** Pushes real-time notifications to a family's open lobby sessions. */
public interface LobbyNotifier {

    void notify(UUID familyId, Map<String, Object> message);

    /** Fallback until the WebSocket lobby registry is implemented. */
    class Noop implements LobbyNotifier {
        @Override
        public void notify(UUID familyId, Map<String, Object> message) {}
    }
}
