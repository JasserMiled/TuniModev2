// src/routes/listingRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired, requireRole } = require("../middleware/auth");
const { getCategoryWithChildren } = require("../services/categoryService");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const router = express.Router();

const allowedGenders = ["homme", "femme", "enfant", "unisexe"];
const normalizeGender = (gender) => {
  if (gender === undefined || gender === null || gender === "") return null;
  const lower = String(gender).toLowerCase();
  return allowedGenders.includes(lower) ? lower : null;
};

const genderByRootSlug = {
  hommes: "homme",
  femmes: "femme",
  enfants: "enfant",
};

const deriveGenderFromCategory = async (categoryId) => {
  if (!categoryId) return null;

  const result = await db.query(
    `WITH RECURSIVE tree AS (
       SELECT id, slug, parent_id FROM categories WHERE id = $1
       UNION ALL
       SELECT c.id, c.slug, c.parent_id
       FROM categories c
       JOIN tree t ON c.id = t.parent_id
     )
     SELECT slug FROM tree WHERE parent_id IS NULL LIMIT 1`,
    [categoryId]
  );

  const rootSlug = result.rows[0]?.slug?.toLowerCase();
  return genderByRootSlug[rootSlug] || null;
};

/**
 * GET /api/listings
 */
router.get("/", async (req, res) => {
  try {
    const { q, category_id, city, min_price, max_price, gender } = req.query;

    const normalizeArrayFilter = (value) => {
      if (value === undefined || value === null) return [];

      const values = Array.isArray(value)
        ? value
        : typeof value === "string"
        ? value.split(",")
        : [];

      return values
        .map((v) => (v === null || v === undefined ? null : String(v).trim().toLowerCase()))
        .filter((v) => v);
    };

    const normalizedSizes = normalizeArrayFilter(req.query.sizes || req.query.size);
    const normalizedColors = normalizeArrayFilter(req.query.colors || req.query.color);
    const deliveryParam = req.query.delivery_available;

    // Build the WHERE clause dynamically based on the filters provided in the query string.
    // We always enforce that a listing must be active, then append additional conditions
    // as the client adds search parameters.
    const conditions = ["l.status = 'active'"];
    const params = [];
    let idx = 1;

    if (q) {
      conditions.push(`(LOWER(l.title) LIKE $${idx} OR LOWER(l.description) LIKE $${idx})`);
      params.push(`%${q.toLowerCase()}%`);
      idx++;
    }
    if (category_id !== undefined) {
      const parsedCategoryId = Number(category_id);

      if (!Number.isInteger(parsedCategoryId) || parsedCategoryId <= 0) {
        return res.status(400).json({ message: "category_id invalide" });
      }

      // Récupère la catégorie sélectionnée ainsi que tous ses descendants
      // via un CTE récursif pour éviter les requêtes N+1, puis filtre
      // les annonces sur cet ensemble d'identifiants.
      const descendantCategoryIds = await getCategoryWithChildren(parsedCategoryId);

      if (descendantCategoryIds.length === 0) {
        return res.json([]);
      }

      conditions.push(`l.category_id = ANY($${idx})`);
      params.push(descendantCategoryIds);
      idx++;
    }
    if (normalizedSizes.length > 0) {
      conditions.push(
        `EXISTS (SELECT 1 FROM unnest(l.sizes) s WHERE LOWER(s) = ANY($${idx}))`
      );
      params.push(normalizedSizes);
      idx++;
    }
    if (normalizedColors.length > 0) {
      conditions.push(
        `EXISTS (SELECT 1 FROM unnest(l.colors) c WHERE LOWER(c) = ANY($${idx}))`
      );
      params.push(normalizedColors);
      idx++;
    }
    if (city) {
      conditions.push(`LOWER(l.city) = $${idx}`);
      params.push(city.toLowerCase());
      idx++;
    }
    if (min_price) {
      conditions.push(`l.price >= $${idx}`);
      params.push(min_price);
      idx++;
    }
    if (max_price) {
      conditions.push(`l.price <= $${idx}`);
      params.push(max_price);
      idx++;
    }

    if (deliveryParam !== undefined) {
      const deliveryValue = typeof deliveryParam === "string"
        ? ["true", "1", "yes", "on"].includes(deliveryParam.toLowerCase())
        : Boolean(deliveryParam);
      conditions.push(`l.delivery_available = $${idx}`);
      params.push(deliveryValue);
      idx++;
    }

    const normalizedGender = normalizeGender(gender);
    if (normalizedGender) {
      conditions.push(`LOWER(l.gender) = $${idx}`);
      params.push(normalizedGender);
      idx++;
    }

    const sql = `
      SELECT
        l.*,
        u.name AS seller_name,
        c.name AS category_name,
        COALESCE(
          (
            SELECT json_agg(
              json_build_object('url', li.url, 'sort_order', li.sort_order)
              ORDER BY li.sort_order
            )
            FROM listing_images li
            WHERE li.listing_id = l.id
          ),
          '[]'::json
        ) AS images
      FROM listings l
      JOIN users u ON l.user_id = u.id
      LEFT JOIN categories c ON l.category_id = c.id
      WHERE ${conditions.join(" AND ")}
      ORDER BY l.created_at DESC
      LIMIT 8
    `;

    const result = await db.query(sql, params);

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/listings/user/:userId
 * Récupère les annonces actives publiées par un utilisateur donné.
 */
router.get("/user/:userId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({ message: "Identifiant utilisateur invalide" });
    }

    const result = await db.query(
      `SELECT
        l.*,
        u.name AS seller_name,
        c.name AS category_name,
        COALESCE(
          (
            SELECT json_agg(
              json_build_object('url', li.url, 'sort_order', li.sort_order)
              ORDER BY li.sort_order
            )
            FROM listing_images li
            WHERE li.listing_id = l.id
          ),
          '[]'::json
        ) AS images
      FROM listings l
      JOIN users u ON l.user_id = u.id
      LEFT JOIN categories c ON l.category_id = c.id
      WHERE l.status = 'active' AND l.user_id = $1
      ORDER BY l.created_at DESC`,
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/listings/:id
 */
router.get("/:id", async (req, res) => {
  try {
    // Fetch the listing along with seller and category metadata in a single query
    // to minimize round-trips before loading related images below.
    const listingRes = await db.query(
      `SELECT l.*, u.name AS seller_name, u.phone AS seller_phone, c.name AS category_name
       FROM listings l
       JOIN users u ON l.user_id = u.id
       LEFT JOIN categories c ON l.category_id = c.id
       WHERE l.id = $1`,
      [req.params.id]
    );
    const listing = listingRes.rows[0];

    if (!listing) return res.status(404).json({ message: "Annonce introuvable" });

    let isOwner = false;
    const authHeader = req.headers.authorization;

    if (authHeader?.startsWith("Bearer ")) {
      try {
        const token = authHeader.substring(7);
        const payload = jwt.verify(token, process.env.JWT_SECRET);
        isOwner = payload?.id === listing.user_id;
      } catch (err) {
        // En cas de token invalide ou expiré, on ignore simplement et on
        // applique la logique par défaut pour les visiteurs.
        isOwner = false;
      }
    }

    if (listing.status === "deleted" && !isOwner) {
      return res.status(404).json({ message: "Cette annonce a été supprimée" });
    }

    const imgRes = await db.query(
      "SELECT id, url, sort_order FROM listing_images WHERE listing_id = $1 ORDER BY sort_order",
      [req.params.id]
    );

    listing.images = imgRes.rows;
    res.json(listing);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/listings/me/mine
 */
router.get("/me/mine", authRequired, requireRole("seller"), async (req, res) => {
  try {
    const result = await db.query(
      `SELECT
        l.*,
        u.name AS seller_name,
        c.name AS category_name,
        COALESCE(
          (
            SELECT json_agg(
              json_build_object('url', li.url, 'sort_order', li.sort_order)
              ORDER BY li.sort_order
            )
            FROM listing_images li
            WHERE li.listing_id = l.id
          ),
          '[]'::json
        ) AS images
      FROM listings l
      JOIN users u ON l.user_id = u.id
      LEFT JOIN categories c ON l.category_id = c.id
      WHERE l.user_id = $1
      ORDER BY l.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * POST /api/listings
 */
router.post("/", authRequired, requireRole("seller"), async (req, res) => {
  try {
    const {
      title,
      description,
      price,
      sizes,
      colors,
      condition,
      category_id,
      city,
      delivery_available,
      images,
    } = req.body;

    const normalizeStringArray = (value) => {
      if (value === undefined) return [];
      if (Array.isArray(value)) {
        return value
          .map((v) => (v === null || v === undefined ? null : String(v).trim()))
          .filter((v) => v);
      }
      if (typeof value === "string") {
        return value
          .split(",")
          .map((v) => v.trim())
          .filter((v) => v);
      }
      return [];
    };

    const resolvedGender = await deriveGenderFromCategory(category_id);

    const parsedSizes = normalizeStringArray(sizes);
    const parsedColors = normalizeStringArray(colors);

    const listingRes = await db.query(
      `INSERT INTO listings
       (user_id, title, description, price, sizes, colors, gender, condition, category_id, city, delivery_available)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [
        req.user.id,
        title,
        description,
        price,
        parsedSizes,
        parsedColors,
        resolvedGender,
        condition,
        category_id || null,
        city || null,
        Boolean(delivery_available),
      ]
    );

    const listing = listingRes.rows[0];

    if (Array.isArray(images) && images.length > 0) {
      // Prepare a single bulk INSERT for images to preserve ordering while
      // avoiding multiple round-trips to the database.
      const values = [];
      const params = [];
      let idx = 1;

      images.forEach((url, i) => {
        values.push(`($${idx}, $${idx + 1}, $${idx + 2})`);
        params.push(listing.id, url, i);
        idx += 3;
      });

      await db.query(
        `INSERT INTO listing_images (listing_id, url, sort_order) VALUES ${values.join(",")}`,
        params
      );
    }

    res.status(201).json(listing);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * PUT /api/listings/:id
 */
router.put("/:id", authRequired, requireRole("seller"), async (req, res) => {
  try {
    const listingId = req.params.id;

    // Ensure the listing exists and the requester is allowed to update it
    // (owner only) before applying any changes.
    const check = await db.query("SELECT user_id FROM listings WHERE id = $1", [listingId]);
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Annonce introuvable" });
    if (found.user_id !== req.user.id) {
      return res.status(403).json({ message: "Vous ne pouvez pas modifier cette annonce" });
    }

    const {
      title,
      description,
      price,
      sizes,
      colors,
      condition,
      category_id,
      city,
      delivery_available,
      status,
      stock,
    } = req.body;

    const normalizeStringArray = (value) => {
      if (value === undefined) return null;
      if (Array.isArray(value)) {
        return value
          .map((v) => (v === null || v === undefined ? null : String(v).trim()))
          .filter((v) => v);
      }
      if (typeof value === "string") {
        const parts = value
          .split(",")
          .map((v) => v.trim())
          .filter((v) => v);
        return parts;
      }
      return [];
    };

    const resolvedGender =
      category_id !== undefined
        ? await deriveGenderFromCategory(category_id)
        : null;
    const categoryProvided = category_id !== undefined;
    const normalizedDelivery =
      delivery_available === undefined ? null : Boolean(delivery_available);

    const parsedSizes = normalizeStringArray(sizes);
    const parsedColors = normalizeStringArray(colors);

    const parsedStock = stock === undefined ? null : Math.max(1, Number(stock) || 1);

    const result = await db.query(
      `UPDATE listings
       SET title = COALESCE($1, title),
           description = COALESCE($2, description),
           price = COALESCE($3, price),
           sizes = COALESCE($4, sizes),
           colors = COALESCE($5, colors),
           gender = CASE WHEN $6 THEN $7 ELSE gender END,
           condition = COALESCE($8, condition),
           category_id = CASE WHEN $6 THEN $9 ELSE category_id END,
           city = COALESCE($10, city),
           delivery_available = COALESCE($11, delivery_available),
           status = COALESCE($12, status),
           stock = COALESCE($13, stock),
           updated_at = NOW()
       WHERE id = $14
       RETURNING *`,
      [
        title,
        description,
        price,
        parsedSizes,
        parsedColors,
        categoryProvided,
        resolvedGender,
        condition,
        category_id,
        city,
        normalizedDelivery,
        status,
        parsedStock,
        listingId,
      ]
    );

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * DELETE /api/listings/:id
 */
router.delete("/:id", authRequired, requireRole("seller"), async (req, res) => {
  try {
    const listingId = req.params.id;

    // Validate ownership before deleting to prevent users from removing
    // listings that are not theirs.
    const check = await db.query("SELECT user_id FROM listings WHERE id = $1", [listingId]);
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Annonce introuvable" });
    if (found.user_id !== req.user.id) {
      return res.status(403).json({ message: "Vous ne pouvez pas supprimer cette annonce" });
    }

    // Rather than deleting the row, mark it as deleted so it still appears in
    // the user's history (e.g. in the "Supprimée" tab of their listings).
    await db.query(
      "UPDATE listings SET status = 'deleted', updated_at = NOW() WHERE id = $1",
      [listingId]
    );

    res.json({ message: "Annonce supprimée" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
