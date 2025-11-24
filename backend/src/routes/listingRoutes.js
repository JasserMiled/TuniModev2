// src/routes/listingRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired, requireRole } = require("../middleware/auth");

const router = express.Router();

/**
 * GET /api/listings
 */
router.get("/", async (req, res) => {
  try {
    const { q, category_id, city, min_price, max_price } = req.query;
    const conditions = ["l.status = 'active'"];
    const params = [];
    let idx = 1;

    if (q) {
      conditions.push(`(LOWER(l.title) LIKE $${idx} OR LOWER(l.description) LIKE $${idx})`);
      params.push(`%${q.toLowerCase()}%`);
      idx++;
    }
    if (category_id) {
      conditions.push(`l.category_id = $${idx}`);
      params.push(category_id);
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

    const sql = `
      SELECT l.*, u.name AS seller_name, c.name AS category_name
      FROM listings l
      JOIN users u ON l.user_id = u.id
      LEFT JOIN categories c ON l.category_id = c.id
      WHERE ${conditions.join(" AND ")}
      ORDER BY l.created_at DESC
      LIMIT 50
    `;

    const result = await db.query(sql, params);
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
router.get("/me/mine", authRequired, requireRole("pro", "admin"), async (req, res) => {
  try {
    const result = await db.query(
      `SELECT * FROM listings WHERE user_id = $1 ORDER BY created_at DESC`,
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
router.post("/", authRequired, requireRole("pro", "admin"), async (req, res) => {
  try {
    const {
      title,
      description,
      price,
      size,
      color,
      condition,
      category_id,
      city,
      images,
    } = req.body;

    const listingRes = await db.query(
      `INSERT INTO listings
       (user_id, title, description, price, size, color, condition, category_id, city)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING *`,
      [
        req.user.id,
        title,
        description,
        price,
        size,
        color,
        condition,
        category_id || null,
        city || null,
      ]
    );

    const listing = listingRes.rows[0];

    if (Array.isArray(images) && images.length > 0) {
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
router.put("/:id", authRequired, requireRole("pro", "admin"), async (req, res) => {
  try {
    const listingId = req.params.id;

    const check = await db.query("SELECT user_id FROM listings WHERE id = $1", [listingId]);
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Annonce introuvable" });
    if (req.user.role !== "admin" && found.user_id !== req.user.id) {
      return res.status(403).json({ message: "Vous ne pouvez pas modifier cette annonce" });
    }

    const {
      title,
      description,
      price,
      size,
      color,
      condition,
      category_id,
      city,
      status,
    } = req.body;

    const result = await db.query(
      `UPDATE listings
       SET title = COALESCE($1, title),
           description = COALESCE($2, description),
           price = COALESCE($3, price),
           size = COALESCE($4, size),
           color = COALESCE($5, color),
           condition = COALESCE($6, condition),
           category_id = COALESCE($7, category_id),
           city = COALESCE($8, city),
           status = COALESCE($9, status),
           updated_at = NOW()
       WHERE id = $10
       RETURNING *`,
      [title, description, price, size, color, condition, category_id, city, status, listingId]
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
router.delete("/:id", authRequired, requireRole("pro", "admin"), async (req, res) => {
  try {
    const listingId = req.params.id;

    const check = await db.query("SELECT user_id FROM listings WHERE id = $1", [listingId]);
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Annonce introuvable" });
    if (req.user.role !== "admin" && found.user_id !== req.user.id) {
      return res.status(403).json({ message: "Vous ne pouvez pas supprimer cette annonce" });
    }

    await db.query("DELETE FROM listings WHERE id = $1", [listingId]);
    res.json({ message: "Annonce supprimée" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
