CREATE TABLE friend_codes (
    code        TEXT PRIMARY KEY CHECK (code ~ '^[A-Z0-9]{6}$'),
    family_id   UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX friend_codes_family_idx ON friend_codes (family_id);
CREATE INDEX friend_codes_expires_idx ON friend_codes (expires_at);

-- One row per pair, smaller id first, so a pair is stored once.
CREATE TABLE friendships (
    family_a    UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    family_b    UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_a, family_b),
    CHECK (family_a < family_b)
);
CREATE INDEX friendships_b_idx ON friendships (family_b);

-- What a family shows to friends: chosen kid cards (no learning levels).
CREATE TABLE showcases (
    family_id   UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    kid_uuid    TEXT NOT NULL CHECK (length(kid_uuid) <= 64),
    payload     JSONB NOT NULL,          -- <= 4 KB, built by the app
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_id, kid_uuid)
);

CREATE TABLE showcase_reactions (
    to_family   UUID NOT NULL,
    to_kid      TEXT NOT NULL,
    from_family UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    kind        TEXT NOT NULL CHECK (kind IN ('clap','heart','star')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (to_family, to_kid, from_family, kind),
    FOREIGN KEY (to_family, to_kid) REFERENCES showcases (family_id, kid_uuid) ON DELETE CASCADE
);
