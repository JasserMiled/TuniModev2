// src/routes/favoriteRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired } = require("../middleware/auth");

const router = express.Router();

/**
 * POST /api/favorites/:listingId
 */
router.post("/:listingId", authRequired, async (req, res) => {
  try {
    const listingId = req.params.listingId;
    await db.query(
      `INSERT INTO favorites (user_id, listing_id)
       VALUES ($1,$2)
       ON CONFLICT DO NOTHING`,
      [req.user.id, listingId]
    );
    res.status(201).json({ message: "Ajouté aux favoris" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * DELETE /api/favorites/:listingId
 */
router.delete("/:listingId", authRequired, async (req, res) => {
  try {
    const listingId = req.params.listingId;
    await db.query(
      `DELETE FROM favorites WHERE user_id = $1 AND listing_id = $2`,
      [req.user.id, listingId]
    );
    res.json({ message: "Retiré des favoris" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/favorites/me
 */
router.get("/me", authRequired, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT l.*, c.name AS category_name
       FROM favorites f
       JOIN listings l ON f.listing_id = l.id
       LEFT JOIN categories c ON l.category_id = c.id
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
