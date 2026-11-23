-- Track devices linked to a family before allowing data uploads.
CREATE TABLE family_devices (
    family_id  UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    device_id  UUID NOT NULL,
    mode       TEXT NOT NULL CHECK (mode IN ('upload', 'replace_local', 'fresh')),
    linked_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_id, device_id)
);

CREATE INDEX sync_records_family_kind_live_idx ON sync_records (family_id, kind) WHERE NOT deleted;
CREATE INDEX refresh_tokens_expires_at_idx ON refresh_tokens (expires_at);

-- Delete existing refresh tokens before adding device_id NOT NULL column
-- (allowed as no mobile app with online sync has been released yet)
DELETE FROM refresh_tokens;
ALTER TABLE refresh_tokens ADD COLUMN device_id UUID NOT NULL;
