// src/routes/orderRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired } = require("../middleware/auth");

const router = express.Router();

/**
 * POST /api/orders
 */
router.post("/", authRequired, async (req, res) => {
  try {
    const { listing_id, quantity, delivery_method, buyer_note } = req.body;

    const listingRes = await db.query(
      "SELECT id, user_id AS seller_id, price FROM listings WHERE id = $1",
      [listing_id]
    );
    const listing = listingRes.rows[0];
    if (!listing) {
      return res.status(404).json({ message: "Annonce introuvable" });
    }

    const total = Number(listing.price) * (quantity || 1);

    const orderRes = await db.query(
      `INSERT INTO orders (buyer_id, seller_id, listing_id, quantity, total_amount, delivery_method, buyer_note)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [
        req.user.id,
        listing.seller_id,
        listing.id,
        quantity || 1,
        total,
        delivery_method || "to_confirm",
        buyer_note || null,
      ]
    );

    res.status(201).json(orderRes.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/orders/me/buyer
 */
router.get("/me/buyer", authRequired, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT o.*, l.title AS listing_title
       FROM orders o
       JOIN listings l ON o.listing_id = l.id
       WHERE o.buyer_id = $1
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/orders/me/seller
 */
router.get("/me/seller", authRequired, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT o.*, l.title AS listing_title
       FROM orders o
       JOIN listings l ON o.listing_id = l.id
       WHERE o.seller_id = $1
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * PATCH /api/orders/:id/status
 */
router.patch("/:id/status", authRequired, async (req, res) => {
  try {
    const { status } = req.body;
    const orderId = req.params.id;

    const allowed = ["pending", "confirmed", "shipped", "delivered", "cancelled"];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: "Statut invalide" });
    }

    const check = await db.query("SELECT seller_id FROM orders WHERE id = $1", [orderId]);
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Commande introuvable" });

    if (found.seller_id !== req.user.id) {
      return res.status(403).json({ message: "Vous ne pouvez pas modifier cette commande" });
    }

    const result = await db.query(
      `UPDATE orders
       SET status = $1,
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [status, orderId]
    );

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
