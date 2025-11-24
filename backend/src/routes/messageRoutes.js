// src/routes/messageRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired } = require("../middleware/auth");

const router = express.Router();

/**
 * POST /api/messages
 */
router.post("/", authRequired, async (req, res) => {
  try {
    const { listing_id, receiver_id, content } = req.body;

    const result = await db.query(
      `INSERT INTO messages (listing_id, sender_id, receiver_id, content)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [listing_id || null, req.user.id, receiver_id, content]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/messages/inbox
 */
router.get("/inbox", authRequired, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT m.*, u.name AS sender_name
       FROM messages m
       JOIN users u ON m.sender_id = u.id
       WHERE m.receiver_id = $1
       ORDER BY m.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/messages/sent
 */
router.get("/sent", authRequired, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT m.*, u.name AS receiver_name
       FROM messages m
       JOIN users u ON m.receiver_id = u.id
       WHERE m.sender_id = $1
       ORDER BY m.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
