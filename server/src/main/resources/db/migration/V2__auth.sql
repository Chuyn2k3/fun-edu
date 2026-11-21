-- Sign in with Google or Apple; exactly one parent account per family.
ALTER TABLE parent_accounts DROP CONSTRAINT parent_accounts_provider_check;
ALTER TABLE parent_accounts ADD CONSTRAINT parent_accounts_provider_check
    CHECK (provider IN ('google', 'apple'));

DROP INDEX parent_accounts_family_id_idx;
ALTER TABLE parent_accounts ADD CONSTRAINT parent_accounts_family_id_key UNIQUE (family_id);

-- Refresh tokens are stored only as SHA-256 hashes and rotated on every use.
CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY,
    parent_id   UUID NOT NULL REFERENCES parent_accounts (id) ON DELETE CASCADE,
    token_hash  BYTEA NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    CONSTRAINT refresh_tokens_token_hash_key UNIQUE (token_hash),
    CONSTRAINT refresh_tokens_hash_length CHECK (length(token_hash) = 32)
);

CREATE INDEX refresh_tokens_parent_id_idx ON refresh_tokens (parent_id);
