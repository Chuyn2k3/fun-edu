-- A family groups the parent account(s) and up to 4 kids.
CREATE TABLE families (
    id          UUID PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A parent signs in with Google; we keep only the stable subject id and email.
CREATE TABLE parent_accounts (
    id          UUID PRIMARY KEY,
    family_id   UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    provider    TEXT NOT NULL CHECK (provider IN ('google')),
    subject     TEXT NOT NULL CHECK (length(subject) BETWEEN 1 AND 255),
    email       TEXT CHECK (email IS NULL OR length(email) <= 320),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT parent_accounts_provider_subject_key UNIQUE (provider, subject)
);

CREATE INDEX parent_accounts_family_id_idx ON parent_accounts (family_id);
