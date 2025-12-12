-- Couleurs centralisées pour éviter le hard-coding côté application
CREATE TABLE IF NOT EXISTS colors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    hex_code VARCHAR(7)
);

INSERT INTO colors (name, hex_code) VALUES
    ('Noir', '#000000'),
    ('Blanc', '#FFFFFF'),
    ('Gris', '#808080'),
    ('Rouge', '#FF0000'),
    ('Bordeaux', '#800020'),
    ('Rose', '#FFC0CB'),
    ('Orange', '#FFA500'),
    ('Jaune', '#FFFF00'),
    ('Vert', '#008000'),
    ('Bleu', '#0000FF'),
    ('Bleu ciel', '#87CEEB'),
    ('Turquoise', '#40E0D0'),
    ('Violet', '#800080'),
    ('Marron', '#8B4513')
ON CONFLICT (name) DO NOTHING;
