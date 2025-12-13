-- Add an optional description for seller accounts so vendors can present their shop.
ALTER TABLE sellers
ADD COLUMN IF NOT EXISTS description TEXT;
