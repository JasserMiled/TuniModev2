// src/routes/adminRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired, requireRole } = require("../middleware/auth");

const router = express.Router();

const accountCte = `
  WITH accounts AS (
    SELECT
      s.id,
      s.name,
      s.email,
      s.phone,
      s.avatar_url,
      s.address,
      'seller' AS role,
      s.store_name AS business_name,
      s.business_id,
      NULL::DATE AS date_of_birth,
      s.created_at
    FROM sellers s
    UNION ALL
    SELECT
      c.id,
      COALESCE(c.profile_name, c.name) AS name,
      c.email,
      c.phone,
      c.avatar_url,
      c.address,
      'client' AS role,
      NULL::TEXT AS business_name,
      NULL::TEXT AS business_id,
      c.date_of_birth,
      c.created_at
    FROM clients c
  )
`;

router.use(authRequired, requireRole("seller"));

router.get("/users", async (req, res) => {
  try {
    const result = await db.query(
      `${accountCte}
       SELECT
         a.id,
         a.name,
         a.email,
         a.phone,
         a.role,
         a.business_name,
         a.business_id,
         a.date_of_birth,
         a.created_at
       FROM accounts a
       ORDER BY a.created_at DESC
       LIMIT 100`
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

router.get("/listings", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT l.*, COALESCE(s.store_name, s.name) AS seller_name
       FROM listings l
       JOIN sellers s ON l.seller_id = s.id
       ORDER BY l.created_at DESC
       LIMIT 200`
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

router.patch("/listings/:id/status", async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ["active", "paused", "deleted"];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: "Statut invalide" });
    }

    const result = await db.query(
      `UPDATE listings
       SET status = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [status, req.params.id]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ message: "Annonce introuvable" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

router.get("/categories", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT * FROM categories ORDER BY name ASC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

router.post("/categories", async (req, res) => {
  try {
    const { name } = req.body;
    const result = await db.query(
      `INSERT INTO categories (name) VALUES ($1) RETURNING *`,
      [name]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
