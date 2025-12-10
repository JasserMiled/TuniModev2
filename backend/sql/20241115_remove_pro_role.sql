BEGIN;

-- Normalize legacy roles to the new model
UPDATE users SET role = 'seller' WHERE role NOT IN ('buyer', 'seller', 'client');
UPDATE users SET role = 'client' WHERE role = 'buyer';

-- Enforce the new role constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users
    ADD CONSTRAINT users_role_check CHECK (role IN ('seller', 'client'));

COMMIT;
