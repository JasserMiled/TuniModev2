-- Create dedicated tables for seller- and client-specific attributes while keeping
-- common fields in the existing users table. The old columns remain for backward
-- compatibility and are marked as deprecated.

CREATE TABLE IF NOT EXISTS sellers (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    store_name VARCHAR(255),
    business_id VARCHAR(100),
    phone VARCHAR(30),
    address TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clients (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    profile_name VARCHAR(255),
    date_of_birth DATE,
    phone VARCHAR(30),
    address TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Backfill legacy data into the new tables so existing accounts remain functional.
INSERT INTO sellers (user_id, store_name, business_id, phone, address, avatar_url, created_at, updated_at)
SELECT
    u.id,
    u.business_name,
    u.business_id,
    u.phone,
    u.address,
    u.avatar_url,
    u.created_at,
    NOW()
FROM users u
WHERE u.role = 'seller'
  AND NOT EXISTS (
    SELECT 1 FROM sellers s WHERE s.user_id = u.id
  );

INSERT INTO clients (user_id, profile_name, date_of_birth, phone, address, avatar_url, created_at, updated_at)
SELECT
    u.id,
    u.name,
    u.date_of_birth,
    u.phone,
    u.address,
    u.avatar_url,
    u.created_at,
    NOW()
FROM users u
WHERE u.role = 'client'
  AND NOT EXISTS (
    SELECT 1 FROM clients c WHERE c.user_id = u.id
  );

-- Mark legacy columns as deprecated without removing them to keep the migration safe.
COMMENT ON COLUMN users.business_name IS 'DEPRECATED: moved to sellers.store_name';
COMMENT ON COLUMN users.business_id IS 'DEPRECATED: moved to sellers.business_id';
COMMENT ON COLUMN users.date_of_birth IS 'DEPRECATED: moved to clients.date_of_birth';
