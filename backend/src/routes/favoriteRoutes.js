// src/routes/favoriteRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired } = require("../middleware/auth");

const router = express.Router();

/**
 * GET /api/favorites/me
 */
router.get("/me", authRequired, async (req, res) => {
  try {
    const favoriteListings = await db.query(
      `SELECT
        l.*,
        c.name AS category_name,
        COALESCE(s.store_name, s.name) AS seller_name,
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
       FROM favorites f
       JOIN listings l ON f.listing_id = l.id
       JOIN sellers s ON l.seller_id = s.id
       LEFT JOIN categories c ON l.category_id = c.id
       WHERE f.client_id = $1
       ORDER BY f.created_at DESC`,
      [req.user.id]
    );

    const favoriteSellers = await db.query(
      `SELECT
         s.id,
         COALESCE(s.store_name, s.name) AS name,
         s.email,
         s.phone,
         s.address,
         s.store_name AS business_name,
         s.avatar_url
       FROM favorite_sellers fs
       JOIN sellers s ON fs.seller_id = s.id
       WHERE fs.client_id = $1
       ORDER BY fs.created_at DESC`,
      [req.user.id]
    );

    res.json({ listings: favoriteListings.rows, sellers: favoriteSellers.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * POST /api/favorites/listings/:listingId
 */
router.post("/listings/:listingId", authRequired, async (req, res) => {
  try {
    const listingId = req.params.listingId;
    await db.query(
      `INSERT INTO favorites (client_id, listing_id)
       VALUES ($1,$2)
       ON CONFLICT DO NOTHING`,
      [req.user.id, listingId]
    );
    res.status(201).json({ message: "Annonce ajoutée aux favoris" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * DELETE /api/favorites/listings/:listingId
 */
router.delete("/listings/:listingId", authRequired, async (req, res) => {
  try {
    const listingId = req.params.listingId;
    await db.query(
      `DELETE FROM favorites WHERE client_id = $1 AND listing_id = $2`,
      [req.user.id, listingId]
    );
    res.json({ message: "Annonce retirée des favoris" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * POST /api/favorites/sellers/:sellerId
 */
router.post("/sellers/:sellerId", authRequired, async (req, res) => {
  try {
    const sellerId = req.params.sellerId;
    await db.query(
      `INSERT INTO favorite_sellers (client_id, seller_id)
       VALUES ($1,$2)
       ON CONFLICT DO NOTHING`,
      [req.user.id, sellerId]
    );
    res.status(201).json({ message: "Vendeur ajouté aux favoris" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * DELETE /api/favorites/sellers/:sellerId
 */
router.delete("/sellers/:sellerId", authRequired, async (req, res) => {
  try {
    const sellerId = req.params.sellerId;
    await db.query(
      `DELETE FROM favorite_sellers WHERE client_id = $1 AND seller_id = $2`,
      [req.user.id, sellerId]
    );
    res.json({ message: "Vendeur retiré des favoris" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
