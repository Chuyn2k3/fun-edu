package com.ibme.funedu.server.sync;

import java.util.Set;
import java.util.regex.Pattern;

/** Which records a family may store. Stroke attempts are not among them; only the best notebook page per glyph. */
public final class SyncKinds {

    public static final Set<String> ALLOWED = Set.of(
            "kid",      // kid profile: nickname, avatar, age
            "glyph",    // writing progress per glyph
            "lesson",   // finished lesson (stars)
            "level",    // level per subject
            "usage",    // seconds used per day
            "reward",   // real reward promised by the parent
            "setting",  // per-kid parent settings (time limit, bedtime, house)
            "race",     // finished race
            "game",     // game profile (cosmic stars, selected rocket)
            "item",     // owned game item
            "badge",    // earned badge
            "counter",  // badge progress counter
            "page");    // best notebook page per glyph

    private static final Pattern KEY = Pattern.compile("[a-z]+:[A-Za-z0-9._:+\\-]{1,190}");

    private SyncKinds() {}

    /** The kind of a valid key, or null. */
    public static String kindOf(String key) {
        if (key == null || !KEY.matcher(key).matches()) return null;
        String kind = key.substring(0, key.indexOf(':'));
        return ALLOWED.contains(kind) ? kind : null;
    }
}
