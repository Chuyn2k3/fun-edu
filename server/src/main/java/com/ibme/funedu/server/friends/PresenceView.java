package com.ibme.funedu.server.friends;

import java.util.UUID;
import org.springframework.stereotype.Component;

/** Read-only view of whether a family currently has an open lobby connection. */
public interface PresenceView {

    boolean isOnline(UUID familyId);

    /** Fallback until the WebSocket lobby registry is implemented. */
    @Component
    class Offline implements PresenceView {
        @Override
        public boolean isOnline(UUID familyId) {
            return false;
        }
    }
}
