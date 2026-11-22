-- Sign in with Apple: Apple's refresh token (AES-GCM sealed, never plain)
-- and the client id it was issued to, so deleting the account can revoke it.
ALTER TABLE parent_accounts
    ADD COLUMN apple_refresh_token TEXT CHECK (apple_refresh_token IS NULL OR length(apple_refresh_token) <= 4096),
    ADD COLUMN apple_client_id TEXT CHECK (apple_client_id IS NULL OR length(apple_client_id) <= 255);
