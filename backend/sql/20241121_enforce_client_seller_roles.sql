BEGIN;

-- Normalize legacy professional roles to the new seller/client model
UPDATE users
SET role = 'seller'
WHERE LOWER(role) IN ('pro', 'professional', 'professional buyer', 'professional seller');

-- Normalize any legacy buyer role to the new client naming
UPDATE users
SET role = 'client'
WHERE LOWER(role) = 'buyer';

-- Force all remaining unexpected roles to seller to keep data consistent
UPDATE users
SET role = 'seller'
WHERE role NOT IN ('seller', 'client');

-- Enforce the strict role constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users
    ADD CONSTRAINT users_role_check CHECK (role IN ('seller', 'client'));

COMMIT;
