// src/routes/orderRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired } = require("../middleware/auth");
const { notifyBuyer, notifySeller } = require("../services/emailService");

const router = express.Router();

/**
 * POST /api/orders
 */
router.post("/", authRequired, async (req, res) => {
  try {
    const {
      listing_id,
      quantity,
      reception_mode,
      buyer_note,
      color,
      size,
      shipping_address,
      phone,
    } = req.body;

    if (!listing_id) {
      return res.status(400).json({ message: "listing_id requis" });
    }

    const listingRes = await db.query(
      "SELECT id, user_id AS seller_id, price, stock, title, colors, sizes FROM listings WHERE id = $1",
      [listing_id]
    );
    const listing = listingRes.rows[0];
    if (!listing) {
      return res.status(404).json({ message: "Annonce introuvable" });
    }

    const normalizedQuantity = Math.max(1, Number(quantity) || 1);
    const availableStock = Number(listing.stock) || 0;
    if (availableStock > 0 && normalizedQuantity > availableStock) {
      return res.status(400).json({ message: "Stock insuffisant pour cette quantité" });
    }

    const normalizedMode =
      reception_mode && String(reception_mode).toLowerCase() === "livraison"
        ? "livraison"
        : "retrait";

    if (normalizedMode === "livraison") {
      if (!shipping_address || !phone) {
        return res
          .status(400)
          .json({ message: "Adresse et téléphone requis pour la livraison" });
      }
    }

    // Validate options against listing if provided
    if (color && Array.isArray(listing.colors) && listing.colors.length > 0) {
      const normalized = listing.colors.map((c) => c.toLowerCase());
      if (!normalized.includes(String(color).toLowerCase())) {
        return res.status(400).json({ message: "Couleur indisponible" });
      }
    }

    if (size && Array.isArray(listing.sizes) && listing.sizes.length > 0) {
      const normalized = listing.sizes.map((s) => s.toLowerCase());
      if (!normalized.includes(String(size).toLowerCase())) {
        return res.status(400).json({ message: "Taille indisponible" });
      }
    }

    const total = Number(listing.price) * normalizedQuantity;

    const orderRes = await db.query(
      `INSERT INTO orders (buyer_id, seller_id, listing_id, quantity, total_amount, reception_mode, shipping_address, phone, color, size, buyer_note)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [
        req.user.id,
        listing.seller_id,
        listing.id,
        normalizedQuantity,
        total,
        normalizedMode,
        normalizedMode === "livraison" ? shipping_address : null,
        normalizedMode === "livraison" ? phone : null,
        color || null,
        size || null,
        buyer_note || null,
      ]
    );

    const order = orderRes.rows[0];

    // Send notification emails (non-blocking but awaited for consistency)
    const buyerEmailRes = await db.query("SELECT email FROM users WHERE id = $1", [req.user.id]);
    const sellerEmailRes = await db.query("SELECT email FROM users WHERE id = $1", [listing.seller_id]);

    const buyerEmail = buyerEmailRes.rows[0]?.email;
    const sellerEmail = sellerEmailRes.rows[0]?.email;

    try {
      if (buyerEmail) await notifyBuyer(order, listing.title, buyerEmail);
      if (sellerEmail) await notifySeller(order, listing.title, sellerEmail);
    } catch (mailErr) {
      console.warn("Erreur lors de l'envoi des emails", mailErr);
    }

    res.status(201).json(order);
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
      `SELECT o.*, COALESCE(l.title, 'Annonce supprimée') AS listing_title
       FROM orders o
       LEFT JOIN listings l ON o.listing_id = l.id
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
      `SELECT o.*, COALESCE(l.title, 'Annonce supprimée') AS listing_title
       FROM orders o
       LEFT JOIN listings l ON o.listing_id = l.id
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

    // Align the API with the database constraint orders_status_check
    const allowedStatuses = [
      "pending",
      "confirmed",
      "shipped",
      "ready_for_pickup",
      "picked_up",
      "received",
      "reception_refused",
      "completed",
      "cancelled",
    ];

    // Automatically normalize legacy/front-end values to valid DB statuses
    const statusAliases = {
      to_confirm: "pending",
      ready_for_pickup: "ready_for_pickup",
      ready: "ready_for_pickup",
      awaiting_pickup: "ready_for_pickup",
      expédié: "shipped",
      expédiée: "shipped",
      expedie: "shipped",
      expediee: "shipped",
      recu: "received",
      reçu: "received",
      refus_de_reception: "reception_refused",
      "refus de reception": "reception_refused",
      "refus_de_réception": "reception_refused",
      done: "completed",
    };

    const rawStatus = status ? String(status).toLowerCase() : "";
    const normalizedStatus = statusAliases[rawStatus] || rawStatus;

    if (!allowedStatuses.includes(normalizedStatus)) {
      return res.status(400).json({ message: "Statut invalide" });
    }

    const check = await db.query(
      "SELECT seller_id, buyer_id, status AS current_status FROM orders WHERE id = $1",
      [orderId]
    );
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Commande introuvable" });

    const isSeller = found.seller_id === req.user.id;
    const isBuyer = found.buyer_id === req.user.id;

    const sellerStatuses = ["confirmed", "shipped", "ready_for_pickup", "picked_up", "cancelled"];

    if (normalizedStatus === "cancelled") {
      if (!isSeller && !isBuyer) {
        return res.status(403).json({ message: "Vous ne pouvez pas modifier cette commande" });
      }

      const buyerCancellableStatuses = ["pending"];
      const sellerCancellableStatuses = ["pending", "confirmed", "shipped", "ready_for_pickup"];

      const canBuyerCancel = isBuyer && buyerCancellableStatuses.includes(found.current_status);
      const canSellerCancel = isSeller && sellerCancellableStatuses.includes(found.current_status);

      if (!canBuyerCancel && !canSellerCancel) {
        return res
          .status(400)
          .json({ message: "La commande ne peut pas être annulée à ce stade" });
      }
    } else if (normalizedStatus === "received") {
      if (!isBuyer) {
        return res.status(403).json({ message: "Seul l'acheteur peut confirmer la réception" });
      }

      const allowedCurrentStatuses = ["shipped", "picked_up"];
      if (!allowedCurrentStatuses.includes(found.current_status)) {
        return res
          .status(400)
          .json({ message: "La commande ne peut pas être marquée comme reçue pour le moment" });
      }
    } else if (normalizedStatus === "reception_refused") {
      if (!isSeller && !isBuyer) {
        return res.status(403).json({ message: "Vous ne pouvez pas modifier cette commande" });
      }

      if (found.current_status !== "shipped") {
        return res.status(400).json({ message: "La commande doit être expédiée pour refuser la réception" });
      }
    } else if (normalizedStatus === "completed") {
      if (!isSeller) {
        return res.status(403).json({ message: "Seul le vendeur peut clôturer la commande" });
      }

      const completableStatuses = ["received", "reception_refused"];
      if (!completableStatuses.includes(found.current_status)) {
        return res
          .status(400)
          .json({ message: "La commande doit être reçue ou refusée avant d'être terminée" });
      }
    } else {
      if (!isSeller) {
        return res.status(403).json({ message: "Vous ne pouvez pas modifier cette commande" });
      }

      if (!sellerStatuses.includes(normalizedStatus)) {
        return res.status(400).json({ message: "Statut vendeur invalide" });
      }
    }

    const result = await db.query(
      `UPDATE orders
       SET status = $1,
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [normalizedStatus, orderId]
    );

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
