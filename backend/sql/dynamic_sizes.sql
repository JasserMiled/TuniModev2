-- Schéma des tailles dynamiques et associations par catégorie
-- Compatible PostgreSQL

CREATE TABLE IF NOT EXISTS sizes (
    id SERIAL PRIMARY KEY,
    label VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS category_sizes (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    size_id INTEGER NOT NULL REFERENCES sizes(id) ON DELETE CASCADE,
    UNIQUE (category_id, size_id)
);

CREATE TABLE IF NOT EXISTS ads (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(id),
    size_id INTEGER NOT NULL REFERENCES sizes(id),
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Catégories de base (insertion idempotente)
INSERT INTO categories (name, slug) VALUES
    ('chaussures', 'chaussures'),
    ('robe', 'robe'),
    ('pantalon', 'pantalon'),
    ('t-shirt', 't-shirt'),
    ('veste', 'veste')
ON CONFLICT (slug) DO NOTHING;

-- Tailles génériques vêtements
INSERT INTO sizes (label) VALUES
    ('XXXS'), ('XXS'), ('XS'), ('S'), ('M'), ('L'), ('XL'), ('XXL')
ON CONFLICT (label) DO NOTHING;

-- Tailles chaussures 37 à 46
INSERT INTO sizes (label)
SELECT to_char(num, 'FM99')
FROM generate_series(37, 46) AS g(num)
ON CONFLICT (label) DO NOTHING;

-- Associations catégories / tailles
WITH shoe_category AS (
    SELECT id FROM categories WHERE slug = 'chaussures'
),
shoe_sizes AS (
    SELECT id FROM sizes WHERE label IN ('37','38','39','40','41','42','43','44','45','46')
)
INSERT INTO category_sizes (category_id, size_id)
SELECT c.id, s.id FROM shoe_category c CROSS JOIN shoe_sizes s
ON CONFLICT DO NOTHING;

WITH dress_category AS (
    SELECT id FROM categories WHERE slug = 'robe'
),
clothing_sizes AS (
    SELECT id FROM sizes WHERE label IN ('XXXS','XXS','XS','S','M','L','XL','XXL')
)
INSERT INTO category_sizes (category_id, size_id)
SELECT c.id, s.id FROM dress_category c CROSS JOIN clothing_sizes s
ON CONFLICT DO NOTHING;
