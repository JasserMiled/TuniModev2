CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    avatar_url TEXT,
    address TEXT,
    role VARCHAR(20) NOT NULL CHECK (role IN ('seller','client')),
    business_name VARCHAR(255), -- DEPRECATED: use sellers.store_name
    business_id VARCHAR(100), -- DEPRECATED: use sellers.business_id
    date_of_birth DATE, -- DEPRECATED: use clients.date_of_birth
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Seller specific attributes are stored separately so that common identity data
-- (email, password, phone...) remain in the users table. The legacy columns stay
-- for backward compatibility during the migration.
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

-- Client specific attributes are stored separately to decouple them from the
-- shared identity information in users.
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

-- ⚠️ ATTENTION : ceci supprime complètement la table categories
DROP TABLE IF EXISTS categories CASCADE;

-- Création de la table categories
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS listings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    sizes TEXT[] NOT NULL DEFAULT ARRAY[]::text[],
    colors TEXT[] NOT NULL DEFAULT ARRAY[]::text[],
    gender VARCHAR(10) CHECK (gender IN ('homme','femme','enfant','unisexe') OR gender IS NULL),
    condition VARCHAR(50),
    category_id INTEGER REFERENCES categories(id),
    city VARCHAR(100),
    delivery_available BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active','paused','deleted')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS listing_images (
    id SERIAL PRIMARY KEY,
    listing_id INTEGER NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    listing_id INTEGER REFERENCES listings(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS favorites (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    listing_id INTEGER NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, listing_id)
);

CREATE TABLE IF NOT EXISTS favorite_sellers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    seller_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, seller_id)
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    buyer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    seller_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    listing_id INTEGER NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    total_amount NUMERIC(10,2) NOT NULL,
    reception_mode VARCHAR(50) NOT NULL DEFAULT 'retrait' CHECK (reception_mode IN ('retrait','livraison')),
    shipping_address TEXT,
    phone VARCHAR(30),
    color TEXT,
    size TEXT,
    buyer_note TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'confirmed',
                'shipped',
                'ready_for_pickup',
                'picked_up',
                'received',
                'reception_refused',
                'completed',
                'cancelled'
            )
        ),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Evaluations entre acheteur et vendeur, liées à une commande existante.
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    reviewer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT reviews_unique_per_order_reviewer UNIQUE (order_id, reviewer_id),
    CONSTRAINT reviews_distinct_users CHECK (reviewer_id <> reviewee_id)
);

-- =========================
--  ENFANTS (FILLE + GARÇON)
-- =========================

INSERT INTO categories (name, slug, parent_id) VALUES ('Enfants', 'enfants', NULL);

INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements pour filles', 'enfants-vetements-pour-filles', (SELECT id FROM categories WHERE slug = 'enfants'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bebe filles', 'enfants-vetements-pour-filles-bebe-filles', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Combinaisons', 'enfants-vetements-pour-filles-bebe-filles-combinaisons', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-bebe-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bodies', 'enfants-vetements-pour-filles-bebe-filles-bodies', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-bebe-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Grenouilleres', 'enfants-vetements-pour-filles-bebe-filles-grenouilleres', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-bebe-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ensembles', 'enfants-vetements-pour-filles-bebe-filles-ensembles', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-bebe-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-filles-bebe-filles-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-bebe-filles'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures', 'enfants-vetements-pour-filles-chaussures', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures bebe', 'enfants-vetements-pour-filles-chaussures-chaussures-bebe', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ballerines', 'enfants-vetements-pour-filles-chaussures-ballerines', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Mocassins et slip-ons', 'enfants-vetements-pour-filles-chaussures-mocassins-et-slip-ons', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bottes', 'enfants-vetements-pour-filles-chaussures-bottes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sandales, claquettes et tongs', 'enfants-vetements-pour-filles-chaussures-sandales-claquettes-et-tongs', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures habillees', 'enfants-vetements-pour-filles-chaussures-chaussures-habillees', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussons et pantoufles', 'enfants-vetements-pour-filles-chaussures-chaussons-et-pantoufles', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de sport', 'enfants-vetements-pour-filles-chaussures-chaussures-de-sport', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Baskets', 'enfants-vetements-pour-filles-chaussures-baskets', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-chaussures'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements d''exterieur', 'enfants-vetements-pour-filles-vetements-dexterieur', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux', 'enfants-vetements-pour-filles-vetements-dexterieur-manteaux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-vetements-dexterieur'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes sans manches', 'enfants-vetements-pour-filles-vetements-dexterieur-vestes-sans-manches', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-vetements-dexterieur'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes', 'enfants-vetements-pour-filles-vetements-dexterieur-vestes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-vetements-dexterieur'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements de pluie', 'enfants-vetements-pour-filles-vetements-dexterieur-vetements-de-pluie', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-vetements-dexterieur'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls & sweats', 'enfants-vetements-pour-filles-pulls-sweats', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls', 'enfants-vetements-pour-filles-pulls-sweats-pulls', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pulls-sweats'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats', 'enfants-vetements-pour-filles-pulls-sweats-sweats', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pulls-sweats'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats a capuche', 'enfants-vetements-pour-filles-pulls-sweats-sweats-a-capuche', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pulls-sweats'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-filles-pulls-sweats-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pulls-sweats'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Tops & t-shirts', 'enfants-vetements-pour-filles-tops-t-shirts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts', 'enfants-vetements-pour-filles-tops-t-shirts-t-shirts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-tops-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Polos', 'enfants-vetements-pour-filles-tops-t-shirts-polos', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-tops-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises', 'enfants-vetements-pour-filles-tops-t-shirts-chemises', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-tops-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemisiers', 'enfants-vetements-pour-filles-tops-t-shirts-chemisiers', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-tops-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-filles-tops-t-shirts-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-tops-t-shirts'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes & robes', 'enfants-vetements-pour-filles-jupes-robes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes', 'enfants-vetements-pour-filles-jupes-robes-robes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-jupes-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes', 'enfants-vetements-pour-filles-jupes-robes-jupes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-jupes-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-filles-jupes-robes-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-jupes-robes'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons et shorts', 'enfants-vetements-pour-filles-pantalons-et-shorts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans', 'enfants-vetements-pour-filles-pantalons-et-shorts-jeans', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans slim', 'enfants-vetements-pour-filles-pantalons-et-shorts-jeans-slim', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Leggings', 'enfants-vetements-pour-filles-pantalons-et-shorts-leggings', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Salopettes', 'enfants-vetements-pour-filles-pantalons-et-shorts-salopettes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts et pantacourts', 'enfants-vetements-pour-filles-pantalons-et-shorts-shorts-et-pantacourts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'enfants-vetements-pour-filles-pantalons-et-shorts-autres', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-pantalons-et-shorts'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Sous-vetements', 'enfants-vetements-pour-filles-sous-vetements', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussettes', 'enfants-vetements-pour-filles-sous-vetements-chaussettes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sous-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Collants', 'enfants-vetements-pour-filles-sous-vetements-collants', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sous-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Culottes', 'enfants-vetements-pour-filles-sous-vetements-culottes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sous-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-filles-sous-vetements-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sous-vetements'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Pyjamas', 'enfants-vetements-pour-filles-pyjamas', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Accessoires', 'enfants-vetements-pour-filles-accessoires', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Casquettes et chapeaux', 'enfants-vetements-pour-filles-accessoires-casquettes-et-chapeaux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Gants', 'enfants-vetements-pour-filles-accessoires-gants', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Echarpes et chales', 'enfants-vetements-pour-filles-accessoires-echarpes-et-chales', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bandeaux et barrettes cheveux', 'enfants-vetements-pour-filles-accessoires-bandeaux-et-barrettes-cheveux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ceintures', 'enfants-vetements-pour-filles-accessoires-ceintures', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bijoux', 'enfants-vetements-pour-filles-accessoires-bijoux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres accessoires', 'enfants-vetements-pour-filles-accessoires-autres-accessoires', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-accessoires'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs & sacs a dos', 'enfants-vetements-pour-filles-sacs-sacs-a-dos', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs a main', 'enfants-vetements-pour-filles-sacs-sacs-a-dos-sacs-a-main', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sacs-sacs-a-dos'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs a dos', 'enfants-vetements-pour-filles-sacs-sacs-a-dos-sacs-a-dos', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sacs-sacs-a-dos'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs d''ecole', 'enfants-vetements-pour-filles-sacs-sacs-a-dos-sacs-decole', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sacs-sacs-a-dos'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres sacs', 'enfants-vetements-pour-filles-sacs-sacs-a-dos-autres-sacs', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sacs-sacs-a-dos'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Sports', 'enfants-vetements-pour-filles-sports', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Maillots de bain', 'enfants-vetements-pour-filles-sports-maillots-de-bain', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sports'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tenues de sport', 'enfants-vetements-pour-filles-sports-tenues-de-sport', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sports'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre equipement sport', 'enfants-vetements-pour-filles-sports-autre-equipement-sport', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-sports'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Deguisements', 'enfants-vetements-pour-filles-deguisements', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Princesses', 'enfants-vetements-pour-filles-deguisements-princesses', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-deguisements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Heros', 'enfants-vetements-pour-filles-deguisements-heros', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-deguisements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Animaux', 'enfants-vetements-pour-filles-deguisements-animaux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-deguisements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Metiers', 'enfants-vetements-pour-filles-deguisements-metiers', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-deguisements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre deguisement', 'enfants-vetements-pour-filles-deguisements-autre-deguisement', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles-deguisements'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Autres vetements', 'enfants-vetements-pour-filles-autres-vetements', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-filles'));


-- =====================
-- GARCONS
-- =====================

INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements pour garcons', 'enfants-vetements-pour-garcons', (SELECT id FROM categories WHERE slug = 'enfants'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Bebe garcons', 'enfants-vetements-pour-garcons-bebe-garcons', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Combinaisons', 'enfants-vetements-pour-garcons-bebe-garcons-combinaisons', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-bebe-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bodies', 'enfants-vetements-pour-garcons-bebe-garcons-bodies', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-bebe-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Grenouilleres', 'enfants-vetements-pour-garcons-bebe-garcons-grenouilleres', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-bebe-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ensembles', 'enfants-vetements-pour-garcons-bebe-garcons-ensembles', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-bebe-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-garcons-bebe-garcons-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-bebe-garcons'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures', 'enfants-vetements-pour-garcons-chaussures', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures bebe', 'enfants-vetements-pour-garcons-chaussures-chaussures-bebe', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Mocassins et chaussures bateau', 'enfants-vetements-pour-garcons-chaussures-mocassins-et-chaussures-bateau', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bottes', 'enfants-vetements-pour-garcons-chaussures-bottes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Espadrilles', 'enfants-vetements-pour-garcons-chaussures-espadrilles', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sandales, claquettes et tongs', 'enfants-vetements-pour-garcons-chaussures-sandales-claquettes-et-tongs', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures habillees', 'enfants-vetements-pour-garcons-chaussures-chaussures-habillees', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussons et pantoufles', 'enfants-vetements-pour-garcons-chaussures-chaussons-et-pantoufles', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de sport', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Foot', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport-foot', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Basket', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport-basket', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tennis', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport-tennis', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Course', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport-course', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Randonnee', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport-randonnee', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport-autres', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Baskets', 'enfants-vetements-pour-garcons-chaussures-baskets', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chaussures'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements d''exterieur', 'enfants-vetements-pour-garcons-vetements-dexterieur', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux', 'enfants-vetements-pour-garcons-vetements-dexterieur-manteaux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-vetements-dexterieur'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes sans manches', 'enfants-vetements-pour-garcons-vetements-dexterieur-vestes-sans-manches', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-vetements-dexterieur'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes', 'enfants-vetements-pour-garcons-vetements-dexterieur-vestes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-vetements-dexterieur'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls & sweats', 'enfants-vetements-pour-garcons-pulls-sweats', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls', 'enfants-vetements-pour-garcons-pulls-sweats-pulls', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pulls-sweats'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats', 'enfants-vetements-pour-garcons-pulls-sweats-sweats', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pulls-sweats'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats a capuche', 'enfants-vetements-pour-garcons-pulls-sweats-sweats-a-capuche', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pulls-sweats'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-garcons-pulls-sweats-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pulls-sweats'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises et t-shirts', 'enfants-vetements-pour-garcons-chemises-et-t-shirts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-t-shirts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Polos', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-polos', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-chemises', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manches courtes', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-manches-courtes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manches longues', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-manches-longues', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sans manches', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-sans-manches', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-garcons-chemises-et-t-shirts-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-chemises-et-t-shirts'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons et shorts', 'enfants-vetements-pour-garcons-pantalons-et-shorts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans', 'enfants-vetements-pour-garcons-pantalons-et-shorts-jeans', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans slim', 'enfants-vetements-pour-garcons-pantalons-et-shorts-jeans-slim', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pattes d''elephant', 'enfants-vetements-pour-garcons-pantalons-et-shorts-pattes-delephant', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Leggings', 'enfants-vetements-pour-garcons-pantalons-et-shorts-leggings', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Salopettes', 'enfants-vetements-pour-garcons-pantalons-et-shorts-salopettes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts & pantacourts', 'enfants-vetements-pour-garcons-pantalons-et-shorts-shorts-pantacourts', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sarouels', 'enfants-vetements-pour-garcons-pantalons-et-shorts-sarouels', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-garcons-pantalons-et-shorts-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pantalons-et-shorts'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Sous-vetements', 'enfants-vetements-pour-garcons-sous-vetements', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussettes', 'enfants-vetements-pour-garcons-sous-vetements-chaussettes', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-sous-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Collants', 'enfants-vetements-pour-garcons-sous-vetements-collants', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-sous-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Boxers / calecons', 'enfants-vetements-pour-garcons-sous-vetements-boxers-calecons', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-sous-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'enfants-vetements-pour-garcons-sous-vetements-autre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-sous-vetements'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Pyjamas', 'enfants-vetements-pour-garcons-pyjamas', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Grenouilleres', 'enfants-vetements-pour-garcons-pyjamas-grenouilleres', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes de chambre', 'enfants-vetements-pour-garcons-pyjamas-robes-de-chambre', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'enfants-vetements-pour-garcons-pyjamas-autres', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-pyjamas'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Accessoires', 'enfants-vetements-pour-garcons-accessoires', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Casquettes et chapeaux', 'enfants-vetements-pour-garcons-accessoires-casquettes-et-chapeaux', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Gants', 'enfants-vetements-pour-garcons-accessoires-gants', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Echarpes et chales', 'enfants-vetements-pour-garcons-accessoires-echarpes-et-chales', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ceintures', 'enfants-vetements-pour-garcons-accessoires-ceintures', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres accessoires', 'enfants-vetements-pour-garcons-accessoires-autres-accessoires', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-accessoires'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Sports', 'enfants-vetements-pour-garcons-sports', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Maillots', 'enfants-vetements-pour-garcons-sports-maillots', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-sports'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tenues sport', 'enfants-vetements-pour-garcons-sports-tenues-sport', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons-sports'));

INSERT INTO categories (name, slug, parent_id) VALUES ('Autres vetements', 'enfants-vetements-pour-garcons-autres-vetements', (SELECT id FROM categories WHERE slug = 'enfants-vetements-pour-garcons'));

-- autres categories enfants globales

INSERT INTO categories (name, slug, parent_id) VALUES ('Jeux et jouets', 'enfants-jeux-et-jouets', (SELECT id FROM categories WHERE slug = 'enfants'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Poussettes, porte-bebe et sieges auto', 'enfants-poussettes-porte-bebe-et-sieges-auto', (SELECT id FROM categories WHERE slug = 'enfants'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Fournitures scolaires', 'enfants-fournitures-scolaires', (SELECT id FROM categories WHERE slug = 'enfants'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres articles pour bebe et enfant', 'enfants-autres-articles-pour-bebe-et-enfant', (SELECT id FROM categories WHERE slug = 'enfants'));


INSERT INTO categories (name, slug, parent_id) VALUES ('Femmes', 'femmes', NULL);
INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements', 'femmes-vetements', (SELECT id FROM categories WHERE slug = 'femmes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux et vestes', 'femmes-vetements-manteaux-et-vestes', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Capes et ponchos', 'femmes-vetements-manteaux-et-vestes-capes-et-ponchos', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux', 'femmes-vetements-manteaux-et-vestes-manteaux', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Duffle-coats', 'femmes-vetements-manteaux-et-vestes-manteaux-duffle-coats', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux en fausse fourrure', 'femmes-vetements-manteaux-et-vestes-manteaux-manteaux-en-fausse-fourrure', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pardessus et manteaux longs', 'femmes-vetements-manteaux-et-vestes-manteaux-pardessus-et-manteaux-longs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Parkas', 'femmes-vetements-manteaux-et-vestes-manteaux-parkas', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cabans', 'femmes-vetements-manteaux-et-vestes-manteaux-cabans', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Impermeables', 'femmes-vetements-manteaux-et-vestes-manteaux-impermeables', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Trenchs', 'femmes-vetements-manteaux-et-vestes-manteaux-trenchs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes sans manches', 'femmes-vetements-manteaux-et-vestes-vestes-sans-manches', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes', 'femmes-vetements-manteaux-et-vestes-vestes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Perfectos et blousons de moto', 'femmes-vetements-manteaux-et-vestes-vestes-perfectos-et-blousons-de-moto', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blousons aviateur', 'femmes-vetements-manteaux-et-vestes-vestes-blousons-aviateur', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes en jean', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-en-jean', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes militaires et utilitaires', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-militaires-et-utilitaires', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes polaires', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-polaires', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Doudounes', 'femmes-vetements-manteaux-et-vestes-vestes-doudounes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes matelassees', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-matelassees', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes chemises', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-chemises', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes de ski et snowboard', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-de-ski-et-snowboard', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blousons teddy', 'femmes-vetements-manteaux-et-vestes-vestes-blousons-teddy', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes coupe-vent', 'femmes-vetements-manteaux-et-vestes-vestes-vestes-coupe-vent', (SELECT id FROM categories WHERE slug = 'femmes-vetements-manteaux-et-vestes-vestes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats et sweats a capuche', 'femmes-vetements-sweats-et-sweats-a-capuche', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats & sweats a capuche', 'femmes-vetements-sweats-et-sweats-a-capuche-sweats-sweats-a-capuche', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats', 'femmes-vetements-sweats-et-sweats-a-capuche-sweats', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Kimonos', 'femmes-vetements-sweats-et-sweats-a-capuche-kimonos', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cardigans', 'femmes-vetements-sweats-et-sweats-a-capuche-cardigans', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Boleros', 'femmes-vetements-sweats-et-sweats-a-capuche-boleros', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes', 'femmes-vetements-sweats-et-sweats-a-capuche-vestes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres pull-overs & sweat-shirts', 'femmes-vetements-sweats-et-sweats-a-capuche-autres-pull-overs-sweat-shirts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-sweats-et-sweats-a-capuche'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blazers et tailleurs', 'femmes-vetements-blazers-et-tailleurs', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blazers', 'femmes-vetements-blazers-et-tailleurs-blazers', (SELECT id FROM categories WHERE slug = 'femmes-vetements-blazers-et-tailleurs'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ensembles tailleur/pantalon', 'femmes-vetements-blazers-et-tailleurs-ensembles-tailleur-pantalon', (SELECT id FROM categories WHERE slug = 'femmes-vetements-blazers-et-tailleurs'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes et robes tailleurs', 'femmes-vetements-blazers-et-tailleurs-jupes-et-robes-tailleurs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-blazers-et-tailleurs'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tailleurs pieces separees', 'femmes-vetements-blazers-et-tailleurs-tailleurs-pieces-separees', (SELECT id FROM categories WHERE slug = 'femmes-vetements-blazers-et-tailleurs'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres ensembles & tailleurs', 'femmes-vetements-blazers-et-tailleurs-autres-ensembles-tailleurs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-blazers-et-tailleurs'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes', 'femmes-vetements-robes', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Mini', 'femmes-vetements-robes-mini', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Midi', 'femmes-vetements-robes-midi', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes longues', 'femmes-vetements-robes-robes-longues', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pour occasions', 'femmes-vetements-robes-pour-occasions', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Fetes et cocktails', 'femmes-vetements-robes-pour-occasions-fetes-et-cocktails', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes-pour-occasions'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes de mariee', 'femmes-vetements-robes-pour-occasions-robes-de-mariee', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes-pour-occasions'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes de bal / fin d''annee', 'femmes-vetements-robes-pour-occasions-robes-de-bal-fin-dannee', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes-pour-occasions'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes de soiree', 'femmes-vetements-robes-pour-occasions-robes-de-soiree', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes-pour-occasions'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes dos nu', 'femmes-vetements-robes-pour-occasions-robes-dos-nu', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes-pour-occasions'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes d''ete', 'femmes-vetements-robes-robes-dete', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes d''hiver', 'femmes-vetements-robes-robes-dhiver', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes chics', 'femmes-vetements-robes-robes-chics', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes casual', 'femmes-vetements-robes-robes-casual', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes sans bretelles', 'femmes-vetements-robes-robes-sans-bretelles', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Petites robes noires', 'femmes-vetements-robes-petites-robes-noires', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes en jean', 'femmes-vetements-robes-robes-en-jean', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres robes', 'femmes-vetements-robes-autres-robes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-robes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes', 'femmes-vetements-jupes', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Minijupes', 'femmes-vetements-jupes-minijupes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jupes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes longueur genou', 'femmes-vetements-jupes-jupes-longueur-genou', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jupes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes midi', 'femmes-vetements-jupes-jupes-midi', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jupes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes longues', 'femmes-vetements-jupes-jupes-longues', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jupes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes asymetriques', 'femmes-vetements-jupes-jupes-asymetriques', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jupes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes-shorts', 'femmes-vetements-jupes-jupes-shorts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jupes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Hauts et t-shirts', 'femmes-vetements-hauts-et-t-shirts', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises', 'femmes-vetements-hauts-et-t-shirts-chemises', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blouses', 'femmes-vetements-hauts-et-t-shirts-blouses', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes', 'femmes-vetements-hauts-et-t-shirts-vestes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts', 'femmes-vetements-hauts-et-t-shirts-t-shirts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Debardeurs', 'femmes-vetements-hauts-et-t-shirts-debardeurs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tuniques', 'femmes-vetements-hauts-et-t-shirts-tuniques', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tops courts', 'femmes-vetements-hauts-et-t-shirts-tops-courts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blouses manches courtes', 'femmes-vetements-hauts-et-t-shirts-blouses-manches-courtes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blouses 3/4', 'femmes-vetements-hauts-et-t-shirts-blouses-3-4', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blouses manches longues', 'femmes-vetements-hauts-et-t-shirts-blouses-manches-longues', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bodies', 'femmes-vetements-hauts-et-t-shirts-bodies', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tops epaules denudees', 'femmes-vetements-hauts-et-t-shirts-tops-epaules-denudees', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cols roules', 'femmes-vetements-hauts-et-t-shirts-cols-roules', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tops peplum', 'femmes-vetements-hauts-et-t-shirts-tops-peplum', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tops dos nu', 'femmes-vetements-hauts-et-t-shirts-tops-dos-nu', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres hauts', 'femmes-vetements-hauts-et-t-shirts-autres-hauts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans', 'femmes-vetements-jeans', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans boyfriend', 'femmes-vetements-jeans-jeans-boyfriend', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans courts', 'femmes-vetements-jeans-jeans-courts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans evases', 'femmes-vetements-jeans-jeans-evases', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans taille haute', 'femmes-vetements-jeans-jeans-taille-haute', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans troues', 'femmes-vetements-jeans-jeans-troues', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans skinny', 'femmes-vetements-jeans-jeans-skinny', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans droits', 'femmes-vetements-jeans-jeans-droits', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'femmes-vetements-jeans-autre', (SELECT id FROM categories WHERE slug = 'femmes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons et leggings', 'femmes-vetements-pantalons-et-leggings', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons courts & chinos', 'femmes-vetements-pantalons-et-leggings-pantalons-courts-chinos', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons a jambes larges', 'femmes-vetements-pantalons-et-leggings-pantalons-a-jambes-larges', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons skinny', 'femmes-vetements-pantalons-et-leggings-pantalons-skinny', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons ajustes', 'femmes-vetements-pantalons-et-leggings-pantalons-ajustes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons droits', 'femmes-vetements-pantalons-et-leggings-pantalons-droits', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons en cuir', 'femmes-vetements-pantalons-et-leggings-pantalons-en-cuir', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Leggings', 'femmes-vetements-pantalons-et-leggings-leggings', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sarouels', 'femmes-vetements-pantalons-et-leggings-sarouels', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres pantalons', 'femmes-vetements-pantalons-et-leggings-autres-pantalons', (SELECT id FROM categories WHERE slug = 'femmes-vetements-pantalons-et-leggings'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts', 'femmes-vetements-shorts', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts taille basse', 'femmes-vetements-shorts-shorts-taille-basse', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts taille haute', 'femmes-vetements-shorts-shorts-taille-haute', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts longueur genou', 'femmes-vetements-shorts-shorts-longueur-genou', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Short en jean', 'femmes-vetements-shorts-short-en-jean', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts en dentelle', 'femmes-vetements-shorts-shorts-en-dentelle', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts en cuir', 'femmes-vetements-shorts-shorts-en-cuir', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts cargo', 'femmes-vetements-shorts-shorts-cargo', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantacourts', 'femmes-vetements-shorts-pantacourts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres shorts', 'femmes-vetements-shorts-autres-shorts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Combinaisons et combishorts', 'femmes-vetements-combinaisons-et-combishorts', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Combinaisons', 'femmes-vetements-combinaisons-et-combishorts-combinaisons', (SELECT id FROM categories WHERE slug = 'femmes-vetements-combinaisons-et-combishorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Combi shorts', 'femmes-vetements-combinaisons-et-combishorts-combi-shorts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-combinaisons-et-combishorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres combinaisons & combishorts', 'femmes-vetements-combinaisons-et-combishorts-autres-combinaisons-combishorts', (SELECT id FROM categories WHERE slug = 'femmes-vetements-combinaisons-et-combishorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Maillots de bain', 'femmes-vetements-maillots-de-bain', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Une piece', 'femmes-vetements-maillots-de-bain-une-piece', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maillots-de-bain'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Deux pieces', 'femmes-vetements-maillots-de-bain-deux-pieces', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maillots-de-bain'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pareos et sarongs', 'femmes-vetements-maillots-de-bain-pareos-et-sarongs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maillots-de-bain'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'femmes-vetements-maillots-de-bain-autres', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maillots-de-bain'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Lingerie et pyjamas', 'femmes-vetements-lingerie-et-pyjamas', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Soutiens-gorge', 'femmes-vetements-lingerie-et-pyjamas-soutiens-gorge', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Culottes', 'femmes-vetements-lingerie-et-pyjamas-culottes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ensembles', 'femmes-vetements-lingerie-et-pyjamas-ensembles', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Gaines', 'femmes-vetements-lingerie-et-pyjamas-gaines', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pyjamas et tenues de nuit', 'femmes-vetements-lingerie-et-pyjamas-pyjamas-et-tenues-de-nuit', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Peignoirs', 'femmes-vetements-lingerie-et-pyjamas-peignoirs', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Collants', 'femmes-vetements-lingerie-et-pyjamas-collants', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussettes', 'femmes-vetements-lingerie-et-pyjamas-chaussettes', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Accessoires de lingerie', 'femmes-vetements-lingerie-et-pyjamas-accessoires-de-lingerie', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'femmes-vetements-lingerie-et-pyjamas-autres', (SELECT id FROM categories WHERE slug = 'femmes-vetements-lingerie-et-pyjamas'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Maternite', 'femmes-vetements-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tops maternite', 'femmes-vetements-maternite-tops-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Robes maternite', 'femmes-vetements-maternite-robes-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jupes maternite', 'femmes-vetements-maternite-jupes-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons maternite', 'femmes-vetements-maternite-pantalons-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts maternite', 'femmes-vetements-maternite-shorts-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Combinaisons & combi shorts maternite', 'femmes-vetements-maternite-combinaisons-combi-shorts-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls a capuche & pulls maternite', 'femmes-vetements-maternite-pulls-a-capuche-pulls-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux & vestes maternite', 'femmes-vetements-maternite-manteaux-vestes-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Maillots & tenues de plage maternite', 'femmes-vetements-maternite-maillots-tenues-de-plage-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sous-vetements maternite', 'femmes-vetements-maternite-sous-vetements-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements de sport maternite', 'femmes-vetements-maternite-vetements-de-sport-maternite', (SELECT id FROM categories WHERE slug = 'femmes-vetements-maternite'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements de sport', 'femmes-vetements-vetements-de-sport', (SELECT id FROM categories WHERE slug = 'femmes-vetements'));

INSERT INTO categories (name, slug, parent_id)
VALUES ('Chaussures', 'femmes-chaussures', (SELECT id FROM categories WHERE slug='femmes'));

-- Baskets
INSERT INTO categories (name, slug, parent_id)
VALUES ('Baskets', 'femmes-chaussures-baskets', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Baskets basses', 'femmes-chaussures-baskets-baskets-basses', (SELECT id FROM categories WHERE slug='femmes-chaussures-baskets'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Baskets montantes', 'femmes-chaussures-baskets-baskets-montantes', (SELECT id FROM categories WHERE slug='femmes-chaussures-baskets'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Baskets plateforme', 'femmes-chaussures-baskets-baskets-plateforme', (SELECT id FROM categories WHERE slug='femmes-chaussures-baskets'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Baskets running', 'femmes-chaussures-baskets-baskets-running', (SELECT id FROM categories WHERE slug='femmes-chaussures-baskets'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Baskets training', 'femmes-chaussures-baskets-baskets-training', (SELECT id FROM categories WHERE slug='femmes-chaussures-baskets'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres baskets', 'femmes-chaussures-baskets-autres-baskets', (SELECT id FROM categories WHERE slug='femmes-chaussures-baskets'));

-- Bottes
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bottes', 'femmes-chaussures-bottes', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bottes mi-mollet', 'femmes-chaussures-bottes-bottes-mi-mollet', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bottes genou', 'femmes-chaussures-bottes-bottes-genou', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Cuissardes', 'femmes-chaussures-bottes-cuissardes', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bottines', 'femmes-chaussures-bottes-bottines', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chelsea boots', 'femmes-chaussures-bottes-chelsea-boots', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bottines plateforme', 'femmes-chaussures-bottes-bottines-plateforme', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres bottes', 'femmes-chaussures-bottes-autres', (SELECT id FROM categories WHERE slug='femmes-chaussures-bottes'));

-- Talons
INSERT INTO categories (name, slug, parent_id)
VALUES ('Talons', 'femmes-chaussures-talons', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Escarpins', 'femmes-chaussures-talons-escarpins', (SELECT id FROM categories WHERE slug='femmes-chaussures-talons'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Talons aiguilles', 'femmes-chaussures-talons-talons-aiguilles', (SELECT id FROM categories WHERE slug='femmes-chaussures-talons'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Talons blocs', 'femmes-chaussures-talons-talons-blocs', (SELECT id FROM categories WHERE slug='femmes-chaussures-talons'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Talons compenses', 'femmes-chaussures-talons-talons-compenses', (SELECT id FROM categories WHERE slug='femmes-chaussures-talons'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sandales a talons', 'femmes-chaussures-talons-sandales-a-talons', (SELECT id FROM categories WHERE slug='femmes-chaussures-talons'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres talons', 'femmes-chaussures-talons-autres-talons', (SELECT id FROM categories WHERE slug='femmes-chaussures-talons'));

-- Chaussures plates
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chaussures plates', 'femmes-chaussures-chaussures-plates', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Mocassins', 'femmes-chaussures-chaussures-plates-mocassins', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Derbies', 'femmes-chaussures-chaussures-plates-derbies', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Richelieus', 'femmes-chaussures-chaussures-plates-richelieus', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Ballerines', 'femmes-chaussures-chaussures-plates-ballerines', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Babies', 'femmes-chaussures-chaussures-plates-babies', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chaussures bateau', 'femmes-chaussures-chaussures-plates-chaussures-bateau', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres chaussures plates', 'femmes-chaussures-chaussures-plates-autres', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-plates'));

-- Sandales / claquettes / tongs
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sandales, claquettes et tongs', 'femmes-chaussures-sandales-claquettes-et-tongs', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sandales', 'femmes-chaussures-sandales-claquettes-et-tongs-sandales', (SELECT id FROM categories WHERE slug='femmes-chaussures-sandales-claquettes-et-tongs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Mules', 'femmes-chaussures-sandales-claquettes-et-tongs-mules', (SELECT id FROM categories WHERE slug='femmes-chaussures-sandales-claquettes-et-tongs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Espadrilles', 'femmes-chaussures-sandales-claquettes-et-tongs-espadrilles', (SELECT id FROM categories WHERE slug='femmes-chaussures-sandales-claquettes-et-tongs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Tongs', 'femmes-chaussures-sandales-claquettes-et-tongs-tongs', (SELECT id FROM categories WHERE slug='femmes-chaussures-sandales-claquettes-et-tongs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Claquettes', 'femmes-chaussures-sandales-claquettes-et-tongs-claquettes', (SELECT id FROM categories WHERE slug='femmes-chaussures-sandales-claquettes-et-tongs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres', 'femmes-chaussures-sandales-claquettes-et-tongs-autres', (SELECT id FROM categories WHERE slug='femmes-chaussures-sandales-claquettes-et-tongs'));

-- Chaussures d’intérieur
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chaussures d''interieur', 'femmes-chaussures-chaussures-d-interieur', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chaussons', 'femmes-chaussures-chaussures-d-interieur-chaussons', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-d-interieur'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Pantoufles', 'femmes-chaussures-chaussures-d-interieur-pantoufles', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-d-interieur'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres', 'femmes-chaussures-chaussures-d-interieur-autres', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-d-interieur'));

-- Chaussures de sport
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chaussures de sport', 'femmes-chaussures-chaussures-de-sport', (SELECT id FROM categories WHERE slug='femmes-chaussures'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Running', 'femmes-chaussures-chaussures-de-sport-running', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Training', 'femmes-chaussures-chaussures-de-sport-training', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Randonnee', 'femmes-chaussures-chaussures-de-sport-randonnee', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Tennis', 'femmes-chaussures-chaussures-de-sport-tennis', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Fitness / Gym', 'femmes-chaussures-chaussures-de-sport-fitness-gym', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres chaussures sport', 'femmes-chaussures-chaussures-de-sport-autres', (SELECT id FROM categories WHERE slug='femmes-chaussures-chaussures-de-sport'));

INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs', 'femmes-sacs', (SELECT id FROM categories WHERE slug='femmes'));

INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs a main', 'femmes-sacs-sacs-a-main', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs a dos', 'femmes-sacs-sacs-a-dos', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs bandouliere', 'femmes-sacs-sacs-bandouliere', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs porte epaule', 'femmes-sacs-sacs-porte-epaule', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs de sport', 'femmes-sacs-sacs-de-sport', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs de voyage', 'femmes-sacs-sacs-de-voyage', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Tote bags', 'femmes-sacs-tote-bags', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Pochettes', 'femmes-sacs-pochettes', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Sacs banane / ceinture', 'femmes-sacs-sacs-banane-ceinture', (SELECT id FROM categories WHERE slug='femmes-sacs'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres sacs', 'femmes-sacs-autres-sacs', (SELECT id FROM categories WHERE slug='femmes-sacs'));

INSERT INTO categories (name, slug, parent_id)
VALUES ('Accessoires', 'femmes-accessoires', (SELECT id FROM categories WHERE slug='femmes'));

-- Bijoux
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Bijoux', 'femmes-accessoires-bijoux', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Colliers', 'femmes-accessoires-bijoux-colliers', (SELECT id FROM categories WHERE slug='femmes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Bracelets', 'femmes-accessoires-bijoux-bracelets', (SELECT id FROM categories WHERE slug='femmes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Bagues', 'femmes-accessoires-bijoux-bagues', (SELECT id FROM categories WHERE slug='femmes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Boucles d''oreilles', 'femmes-accessoires-bijoux-boucles-d-oreilles', (SELECT id FROM categories WHERE slug='femmes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Piercings', 'femmes-accessoires-bijoux-piercings', (SELECT id FROM categories WHERE slug='femmes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) 
VALUES ('Autres bijoux', 'femmes-accessoires-bijoux-autres', (SELECT id FROM categories WHERE slug='femmes-accessoires-bijoux'));

-- Ceintures
INSERT INTO categories (name, slug, parent_id)
VALUES ('Ceintures', 'femmes-accessoires-ceintures', (SELECT id FROM categories WHERE slug='femmes-accessoires'));

-- Chapeaux
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chapeaux', 'femmes-accessoires-chapeaux', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Berets', 'femmes-accessoires-chapeaux-berets', (SELECT id FROM categories WHERE slug='femmes-accessoires-chapeaux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bonnets', 'femmes-accessoires-chapeaux-bonnets', (SELECT id FROM categories WHERE slug='femmes-accessoires-chapeaux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Casquettes', 'femmes-accessoires-chapeaux-casquettes', (SELECT id FROM categories WHERE slug='femmes-accessoires-chapeaux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chapeaux ete', 'femmes-accessoires-chapeaux-chapeaux-ete', (SELECT id FROM categories WHERE slug='femmes-accessoires-chapeaux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres chapeaux', 'femmes-accessoires-chapeaux-autres', (SELECT id FROM categories WHERE slug='femmes-accessoires-chapeaux'));

-- Gants / Écharpes
INSERT INTO categories (name, slug, parent_id)
VALUES ('Gants', 'femmes-accessoires-gants', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Echarpes et foulards', 'femmes-accessoires-echarpes-et-foulards', (SELECT id FROM categories WHERE slug='femmes-accessoires'));

-- Lunettes
INSERT INTO categories (name, slug, parent_id)
VALUES ('Lunettes de soleil', 'femmes-accessoires-lunettes-de-soleil', (SELECT id FROM categories WHERE slug='femmes-accessoires'));

-- Accessoires cheveux
INSERT INTO categories (name, slug, parent_id)
VALUES ('Accessoires cheveux', 'femmes-accessoires-accessoires-cheveux', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Chouchous', 'femmes-accessoires-accessoires-cheveux-chouchous', (SELECT id FROM categories WHERE slug='femmes-accessoires-accessoires-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Barrettes', 'femmes-accessoires-accessoires-cheveux-barrettes', (SELECT id FROM categories WHERE slug='femmes-accessoires-accessoires-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Serre-tetes', 'femmes-accessoires-accessoires-cheveux-serre-tetes', (SELECT id FROM categories WHERE slug='femmes-accessoires-accessoires-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Bandanas', 'femmes-accessoires-accessoires-cheveux-bandanas', (SELECT id FROM categories WHERE slug='femmes-accessoires-accessoires-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres accessoires cheveux', 'femmes-accessoires-accessoires-cheveux-autres', (SELECT id FROM categories WHERE slug='femmes-accessoires-accessoires-cheveux'));

-- Reste
INSERT INTO categories (name, slug, parent_id)
VALUES ('Portefeuilles', 'femmes-accessoires-portefeuilles', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Etuis telephone', 'femmes-accessoires-etuis-telephone', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Porte-cartes', 'femmes-accessoires-porte-cartes', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Montres', 'femmes-accessoires-montres', (SELECT id FROM categories WHERE slug='femmes-accessoires'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres accessoires', 'femmes-accessoires-autres', (SELECT id FROM categories WHERE slug='femmes-accessoires'));

INSERT INTO categories (name, slug, parent_id)
VALUES ('Beaute', 'femmes-beaute', (SELECT id FROM categories WHERE slug='femmes'));

-- Maquillage
INSERT INTO categories (name, slug, parent_id)
VALUES ('Maquillage', 'femmes-beaute-maquillage', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Teint', 'femmes-beaute-maquillage-teint', (SELECT id FROM categories WHERE slug='femmes-beaute-maquillage'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Yeux', 'femmes-beaute-maquillage-yeux', (SELECT id FROM categories WHERE slug='femmes-beaute-maquillage'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Levres', 'femmes-beaute-maquillage-levres', (SELECT id FROM categories WHERE slug='femmes-beaute-maquillage'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Ongles', 'femmes-beaute-maquillage-ongles', (SELECT id FROM categories WHERE slug='femmes-beaute-maquillage'));

-- Parfums
INSERT INTO categories (name, slug, parent_id)
VALUES ('Parfums', 'femmes-beaute-parfums', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Parfums femme', 'femmes-beaute-parfums-parfums-femme', (SELECT id FROM categories WHERE slug='femmes-beaute-parfums'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Brumes corporelles', 'femmes-beaute-parfums-brumes-corporelles', (SELECT id FROM categories WHERE slug='femmes-beaute-parfums'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Coffrets', 'femmes-beaute-parfums-coffrets', (SELECT id FROM categories WHERE slug='femmes-beaute-parfums'));

-- Soins du visage
INSERT INTO categories (name, slug, parent_id)
VALUES ('Soins du visage', 'femmes-beaute-soins-du-visage', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Cremes', 'femmes-beaute-soins-du-visage-cremes', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-visage'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Serums', 'femmes-beaute-soins-du-visage-serums', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-visage'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Masques', 'femmes-beaute-soins-du-visage-masques', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-visage'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Nettoyants', 'femmes-beaute-soins-du-visage-nettoyants', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-visage'));

-- Soins du corps
INSERT INTO categories (name, slug, parent_id)
VALUES ('Soins du corps', 'femmes-beaute-soins-du-corps', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Gels douche', 'femmes-beaute-soins-du-corps-gels-douche', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-corps'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Hydratants', 'femmes-beaute-soins-du-corps-hydratants', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-corps'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Huiles', 'femmes-beaute-soins-du-corps-huiles', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-corps'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Gommages', 'femmes-beaute-soins-du-corps-gommages', (SELECT id FROM categories WHERE slug='femmes-beaute-soins-du-corps'));

-- Cheveux
INSERT INTO categories (name, slug, parent_id)
VALUES ('Cheveux', 'femmes-beaute-cheveux', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Shampoings', 'femmes-beaute-cheveux-shampoings', (SELECT id FROM categories WHERE slug='femmes-beaute-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Apres-shampoings', 'femmes-beaute-cheveux-apres-shampoings', (SELECT id FROM categories WHERE slug='femmes-beaute-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Masques', 'femmes-beaute-cheveux-masques', (SELECT id FROM categories WHERE slug='femmes-beaute-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Colorations', 'femmes-beaute-cheveux-colorations', (SELECT id FROM categories WHERE slug='femmes-beaute-cheveux'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Accessoires cheveux', 'femmes-beaute-cheveux-accessoires-cheveux', (SELECT id FROM categories WHERE slug='femmes-beaute-cheveux'));

-- Coffrets / accessoires
INSERT INTO categories (name, slug, parent_id)
VALUES ('Coffrets beaute', 'femmes-beaute-coffrets-beaute', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Accessoires beaute', 'femmes-beaute-accessoires-beaute', (SELECT id FROM categories WHERE slug='femmes-beaute'));
INSERT INTO categories (name, slug, parent_id)
VALUES ('Autres produits beaute', 'femmes-beaute-autres', (SELECT id FROM categories WHERE slug='femmes-beaute'));


INSERT INTO categories (name, slug, parent_id) VALUES ('Hommes', 'hommes', NULL);
INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements', 'hommes-vetements', (SELECT id FROM categories WHERE slug = 'hommes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sous-vetements et chaussettes', 'hommes-vetements-sous-vetements-et-chaussettes', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sous-vetements', 'hommes-vetements-sous-vetements-et-chaussettes-sous-vetements', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sous-vetements-et-chaussettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussettes', 'hommes-vetements-sous-vetements-et-chaussettes-chaussettes', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sous-vetements-et-chaussettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Peignoirs', 'hommes-vetements-sous-vetements-et-chaussettes-peignoirs', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sous-vetements-et-chaussettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'hommes-vetements-sous-vetements-et-chaussettes-autres', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sous-vetements-et-chaussettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Manteaux', 'hommes-vetements-manteaux', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Duffle-coats', 'hommes-vetements-manteaux-duffle-coats', (SELECT id FROM categories WHERE slug = 'hommes-vetements-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pardessus et manteaux longs', 'hommes-vetements-manteaux-pardessus-et-manteaux-longs', (SELECT id FROM categories WHERE slug = 'hommes-vetements-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Parkas', 'hommes-vetements-manteaux-parkas', (SELECT id FROM categories WHERE slug = 'hommes-vetements-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cabans', 'hommes-vetements-manteaux-cabans', (SELECT id FROM categories WHERE slug = 'hommes-vetements-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Impermeables', 'hommes-vetements-manteaux-impermeables', (SELECT id FROM categories WHERE slug = 'hommes-vetements-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Trenchs', 'hommes-vetements-manteaux-trenchs', (SELECT id FROM categories WHERE slug = 'hommes-vetements-manteaux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Hauts et t-shirts', 'hommes-vetements-hauts-et-t-shirts', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises', 'hommes-vetements-hauts-et-t-shirts-chemises', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises a carreaux', 'hommes-vetements-hauts-et-t-shirts-chemises-chemises-a-carreaux', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-chemises'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises en jean', 'hommes-vetements-hauts-et-t-shirts-chemises-chemises-en-jean', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-chemises'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises unies', 'hommes-vetements-hauts-et-t-shirts-chemises-chemises-unies', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-chemises'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises a motifs', 'hommes-vetements-hauts-et-t-shirts-chemises-chemises-a-motifs', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-chemises'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chemises a rayures', 'hommes-vetements-hauts-et-t-shirts-chemises-chemises-a-rayures', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-chemises'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres chemises', 'hommes-vetements-hauts-et-t-shirts-chemises-autres-chemises', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-chemises'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts', 'hommes-vetements-hauts-et-t-shirts-t-shirts', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts unis', 'hommes-vetements-hauts-et-t-shirts-t-shirts-t-shirts-unis', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts imprimes', 'hommes-vetements-hauts-et-t-shirts-t-shirts-t-shirts-imprimes', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts a rayures', 'hommes-vetements-hauts-et-t-shirts-t-shirts-t-shirts-a-rayures', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Polos', 'hommes-vetements-hauts-et-t-shirts-t-shirts-polos', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts a manches longues', 'hommes-vetements-hauts-et-t-shirts-t-shirts-t-shirts-a-manches-longues', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres T-shirts', 'hommes-vetements-hauts-et-t-shirts-t-shirts-autres-t-shirts', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts sans manches', 'hommes-vetements-hauts-et-t-shirts-t-shirts-sans-manches', (SELECT id FROM categories WHERE slug = 'hommes-vetements-hauts-et-t-shirts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Costumes et blazers', 'hommes-vetements-costumes-et-blazers', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Blazers', 'hommes-vetements-costumes-et-blazers-blazers', (SELECT id FROM categories WHERE slug = 'hommes-vetements-costumes-et-blazers'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons de costume', 'hommes-vetements-costumes-et-blazers-pantalons-de-costume', (SELECT id FROM categories WHERE slug = 'hommes-vetements-costumes-et-blazers'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Gilets de costume', 'hommes-vetements-costumes-et-blazers-gilets-de-costume', (SELECT id FROM categories WHERE slug = 'hommes-vetements-costumes-et-blazers'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ensembles costume', 'hommes-vetements-costumes-et-blazers-ensembles-costume', (SELECT id FROM categories WHERE slug = 'hommes-vetements-costumes-et-blazers'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Costumes de mariage', 'hommes-vetements-costumes-et-blazers-costumes-de-mariage', (SELECT id FROM categories WHERE slug = 'hommes-vetements-costumes-et-blazers'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'hommes-vetements-costumes-et-blazers-autres', (SELECT id FROM categories WHERE slug = 'hommes-vetements-costumes-et-blazers'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats et pulls', 'hommes-vetements-sweats-et-pulls', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats', 'hommes-vetements-sweats-et-pulls-sweats', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls et pulls a capuche', 'hommes-vetements-sweats-et-pulls-pulls-et-pulls-a-capuche', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls a capuche avec zip', 'hommes-vetements-sweats-et-pulls-pulls-a-capuche-avec-zip', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cardigans', 'hommes-vetements-sweats-et-pulls-cardigans', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls ras de cou', 'hommes-vetements-sweats-et-pulls-pulls-ras-de-cou', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats a col V', 'hommes-vetements-sweats-et-pulls-sweats-a-col-v', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls a col roule', 'hommes-vetements-sweats-et-pulls-pulls-a-col-roule', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats longs', 'hommes-vetements-sweats-et-pulls-sweats-longs', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pulls d''hiver', 'hommes-vetements-sweats-et-pulls-pulls-dhiver', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes', 'hommes-vetements-sweats-et-pulls-vestes', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres', 'hommes-vetements-sweats-et-pulls-autres', (SELECT id FROM categories WHERE slug = 'hommes-vetements-sweats-et-pulls'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts', 'hommes-vetements-shorts', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts cargo', 'hommes-vetements-shorts-shorts-cargo', (SELECT id FROM categories WHERE slug = 'hommes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts chino', 'hommes-vetements-shorts-shorts-chino', (SELECT id FROM categories WHERE slug = 'hommes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts en jean', 'hommes-vetements-shorts-shorts-en-jean', (SELECT id FROM categories WHERE slug = 'hommes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres shorts', 'hommes-vetements-shorts-autres-shorts', (SELECT id FROM categories WHERE slug = 'hommes-vetements-shorts'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons', 'hommes-vetements-pantalons', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons cargo', 'hommes-vetements-pantalons-pantalons-cargo', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons chinos', 'hommes-vetements-pantalons-pantalons-chinos', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons en jean', 'hommes-vetements-pantalons-pantalons-en-jean', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons de costume', 'hommes-vetements-pantalons-pantalons-de-costume', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons habilles', 'hommes-vetements-pantalons-pantalons-habilles', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons jogging', 'hommes-vetements-pantalons-pantalons-jogging', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons en toile', 'hommes-vetements-pantalons-pantalons-en-toile', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons de travail', 'hommes-vetements-pantalons-pantalons-de-travail', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons thermiques', 'hommes-vetements-pantalons-pantalons-thermiques', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres pantalons', 'hommes-vetements-pantalons-autres-pantalons', (SELECT id FROM categories WHERE slug = 'hommes-vetements-pantalons'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans', 'hommes-vetements-jeans', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans skinny', 'hommes-vetements-jeans-jeans-skinny', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans slim', 'hommes-vetements-jeans-jeans-slim', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans droits', 'hommes-vetements-jeans-jeans-droits', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans bootcut', 'hommes-vetements-jeans-jeans-bootcut', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans relaxed', 'hommes-vetements-jeans-jeans-relaxed', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Jeans baggy', 'hommes-vetements-jeans-jeans-baggy', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres jeans', 'hommes-vetements-jeans-autres-jeans', (SELECT id FROM categories WHERE slug = 'hommes-vetements-jeans'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Survetements et sport', 'hommes-vetements-survetements-et-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Survetements', 'hommes-vetements-survetements-et-sport-survetements', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vetements de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('T-shirts de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-t-shirts-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Shorts de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-shorts-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Pantalons de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-pantalons-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Vestes de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-vestes-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sweats de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-sweats-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Collants et leggings sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-collants-et-leggings-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autres vetements de sport', 'hommes-vetements-survetements-et-sport-vetements-de-sport-autres-vetements-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport-vetements-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Tenues specifiques (fitness, gym, etc.)', 'hommes-vetements-survetements-et-sport-tenues-specifiques-fitness-gym-etc', (SELECT id FROM categories WHERE slug = 'hommes-vetements-survetements-et-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Maillots de bain', 'hommes-vetements-maillots-de-bain', (SELECT id FROM categories WHERE slug = 'hommes-vetements'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures', 'hommes-chaussures', (SELECT id FROM categories WHERE slug = 'hommes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Mocassins et chaussures bateau', 'hommes-chaussures-mocassins-et-chaussures-bateau', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bottes', 'hommes-chaussures-bottes', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Mules et sabots', 'hommes-chaussures-mules-et-sabots', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Espadrilles', 'hommes-chaussures-espadrilles', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Claquettes et tongs', 'hommes-chaussures-claquettes-et-tongs', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sandales', 'hommes-chaussures-sandales', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussons et pantoufles', 'hommes-chaussures-chaussons-et-pantoufles', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de sport', 'hommes-chaussures-chaussures-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de basket', 'hommes-chaussures-chaussures-de-sport-chaussures-de-basket', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de cyclisme', 'hommes-chaussures-chaussures-de-sport-chaussures-de-cyclisme', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de danse', 'hommes-chaussures-chaussures-de-sport-chaussures-de-danse', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de foot', 'hommes-chaussures-chaussures-de-sport-chaussures-de-foot', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de golf', 'hommes-chaussures-chaussures-de-sport-chaussures-de-golf', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures et bottes de randonnee', 'hommes-chaussures-chaussures-de-sport-chaussures-et-bottes-de-randonnee', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de foot en salle', 'hommes-chaussures-chaussures-de-sport-chaussures-de-foot-en-salle', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de fitness', 'hommes-chaussures-chaussures-de-sport-chaussures-de-fitness', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bottes de moto', 'hommes-chaussures-chaussures-de-sport-bottes-de-moto', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Patins a roulettes et rollers', 'hommes-chaussures-chaussures-de-sport-patins-a-roulettes-et-rollers', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de course', 'hommes-chaussures-chaussures-de-sport-chaussures-de-course', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chaussures de tennis', 'hommes-chaussures-chaussures-de-sport-chaussures-de-tennis', (SELECT id FROM categories WHERE slug = 'hommes-chaussures-chaussures-de-sport'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Baskets', 'hommes-chaussures-baskets', (SELECT id FROM categories WHERE slug = 'hommes-chaussures'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Accessoires', 'hommes-accessoires', (SELECT id FROM categories WHERE slug = 'hommes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs et sacoches', 'hommes-accessoires-sacs-et-sacoches', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs a dos', 'hommes-accessoires-sacs-et-sacoches-sacs-a-dos', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-sacs-et-sacoches'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Sacs de sport', 'hommes-accessoires-sacs-et-sacoches-sacs-de-sport', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-sacs-et-sacoches'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cartables et sacoches', 'hommes-accessoires-sacs-et-sacoches-cartables-et-sacoches', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-sacs-et-sacoches'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Porte-monnaie', 'hommes-accessoires-sacs-et-sacoches-porte-monnaie', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-sacs-et-sacoches'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Porte-feuille', 'hommes-accessoires-sacs-et-sacoches-porte-feuille', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-sacs-et-sacoches'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Ceintures', 'hommes-accessoires-ceintures', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Gants', 'hommes-accessoires-gants', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chapeaux et casquettes', 'hommes-accessoires-chapeaux-et-casquettes', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bonnets', 'hommes-accessoires-chapeaux-et-casquettes-bonnets', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-chapeaux-et-casquettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Casquettes', 'hommes-accessoires-chapeaux-et-casquettes-casquettes', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-chapeaux-et-casquettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Chapeaux', 'hommes-accessoires-chapeaux-et-casquettes-chapeaux', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-chapeaux-et-casquettes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bijoux', 'hommes-accessoires-bijoux', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bracelets', 'hommes-accessoires-bijoux-bracelets', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Colliers', 'hommes-accessoires-bijoux-colliers', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Bagues', 'hommes-accessoires-bijoux-bagues', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Autre', 'hommes-accessoires-bijoux-autre', (SELECT id FROM categories WHERE slug = 'hommes-accessoires-bijoux'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Echarpes et chales', 'hommes-accessoires-echarpes-et-chales', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Lunettes de soleil', 'hommes-accessoires-lunettes-de-soleil', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Cravates et nœuds papillons', 'hommes-accessoires-cravates-et-n-uds-papillons', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Montres', 'hommes-accessoires-montres', (SELECT id FROM categories WHERE slug = 'hommes-accessoires'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Soins', 'hommes-soins', (SELECT id FROM categories WHERE slug = 'hommes'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Soins visage', 'hommes-soins-soins-visage', (SELECT id FROM categories WHERE slug = 'hommes-soins'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Soins cheveux', 'hommes-soins-soins-cheveux', (SELECT id FROM categories WHERE slug = 'hommes-soins'));
INSERT INTO categories (name, slug, parent_id) VALUES ('Parfums', 'hommes-soins-parfums', (SELECT id FROM categories WHERE slug = 'hommes-soins'));
