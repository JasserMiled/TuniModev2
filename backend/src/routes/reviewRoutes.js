// src/routes/reviewRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired } = require("../middleware/auth");

const router = express.Router();

// Vérifie qu'une commande existe bien entre l'acheteur et le vendeur avant d'autoriser un avis.
const fetchOrderForReview = async (orderId, userId) => {
  const orderRes = await db.query(
    "SELECT id, buyer_id, seller_id FROM orders WHERE id = $1",
    [orderId]
  );
  const order = orderRes.rows[0];
  if (!order) return null;

  const isBuyer = order.buyer_id === userId;
  const isSeller = order.seller_id === userId;

  if (!isBuyer && !isSeller) {
    return { forbidden: true };
  }

  return { order, isBuyer, isSeller };
};

/**
 * POST /api/reviews
 * Laisse un avis (note + commentaire optionnel) si une commande existe entre les deux utilisateurs.
 */
router.post("/", authRequired, async (req, res) => {
  try {
    const { order_id, rating, comment } = req.body;

    if (!order_id) {
      return res.status(400).json({ message: "order_id requis" });
    }

    const normalizedRating = Number(rating);
    if (!Number.isInteger(normalizedRating) || normalizedRating < 1 || normalizedRating > 5) {
      return res.status(400).json({ message: "La note doit être un entier entre 1 et 5" });
    }

    const validation = await fetchOrderForReview(order_id, req.user.id);
    if (!validation) {
      return res.status(404).json({ message: "Commande introuvable" });
    }
    if (validation.forbidden) {
      return res.status(403).json({ message: "Vous ne pouvez pas évaluer cette commande" });
    }

    const { order, isBuyer } = validation;
    const revieweeId = isBuyer ? order.seller_id : order.buyer_id;

    const existing = await db.query(
      "SELECT id FROM reviews WHERE order_id = $1 AND reviewer_id = $2",
      [order_id, req.user.id]
    );
    if (existing.rows[0]) {
      return res
        .status(400)
        .json({ message: "Vous avez déjà laissé un avis pour cette commande" });
    }

    const result = await db.query(
      `INSERT INTO reviews (order_id, reviewer_id, reviewee_id, rating, comment)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [order_id, req.user.id, revieweeId, normalizedRating, comment || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/reviews/order/:orderId
 * Retourne les avis liés à une commande, accessible uniquement par l'acheteur ou le vendeur.
 */
router.get("/order/:orderId", authRequired, async (req, res) => {
  try {
    const orderId = req.params.orderId;
    const validation = await fetchOrderForReview(orderId, req.user.id);
    if (!validation) {
      return res.status(404).json({ message: "Commande introuvable" });
    }
    if (validation.forbidden) {
      return res.status(403).json({ message: "Accès refusé" });
    }

    const reviews = await db.query(
      `SELECT r.*, u.name AS reviewer_name
       FROM reviews r
       JOIN users u ON r.reviewer_id = u.id
       WHERE r.order_id = $1
       ORDER BY r.created_at ASC`,
      [orderId]
    );

    res.json(reviews.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

/**
 * GET /api/reviews/user/:userId
 * Liste les avis reçus par un utilisateur (publique).
 */
router.get("/user/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
    const reviews = await db.query(
      `SELECT r.*, u.name AS reviewer_name
       FROM reviews r
       JOIN users u ON r.reviewer_id = u.id
       WHERE r.reviewee_id = $1
       ORDER BY r.created_at DESC`,
      [userId]
    );

    res.json(reviews.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
