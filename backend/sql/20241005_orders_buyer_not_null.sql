-- Enforce buyer linkage on orders
BEGIN;

-- Remove any historical rows without a buyer to satisfy the NOT NULL constraint
DELETE FROM orders WHERE buyer_id IS NULL;

ALTER TABLE orders
  ALTER COLUMN buyer_id SET NOT NULL;

-- Recreate foreign key to ensure referential integrity
ALTER TABLE orders
  DROP CONSTRAINT IF EXISTS orders_buyer_id_fkey;

ALTER TABLE orders
  ADD CONSTRAINT orders_buyer_id_fkey
    FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE CASCADE;

COMMIT;
