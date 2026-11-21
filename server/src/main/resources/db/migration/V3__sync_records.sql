-- Synced family data as keyed records ("kid:<uuid>", "glyph:<kid>:<id>", ...).
-- The app merges; the server stores, orders and guards against stale writes.
CREATE SEQUENCE sync_version_seq;

CREATE TABLE sync_records (
    family_id   UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    key         TEXT NOT NULL CHECK (length(key) BETWEEN 3 AND 200),
    kind        TEXT NOT NULL,
    payload     JSONB,
    deleted     BOOLEAN NOT NULL DEFAULT false,
    version     BIGINT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_id, key),
    CONSTRAINT sync_records_tombstone CHECK ((deleted AND payload IS NULL) OR (NOT deleted AND payload IS NOT NULL))
);

-- Pull = "everything of this family after version N", in version order.
CREATE INDEX sync_records_family_version_idx ON sync_records (family_id, version);
