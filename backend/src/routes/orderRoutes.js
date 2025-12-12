// src/routes/orderRoutes.js
const express = require("express");
const db = require("../db");
const { authRequired, requireRole } = require("../middleware/auth");
const { notifyBuyer, notifySeller } = require("../services/emailService");

const router = express.Router();
const addClientAlias = (order) => ({ ...order, client_id: order.buyer_id });

/**
 * POST /api/orders
 */
router.post("/", authRequired, requireRole("client"), async (req, res) => {
  try {
    console.log("[Orders] Extracted user ID from token:", req.user?.id);

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
      "SELECT id, seller_id, price, title, colors, sizes, reference_code FROM listings WHERE id = $1",
      [listing_id]
    );
    const listing = listingRes.rows[0];
    if (!listing) {
      return res.status(404).json({ message: "Annonce introuvable" });
    }

    const normalizedQuantity = Math.max(1, Number(quantity) || 1);
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

    console.log("[Orders] Inserting order with client_id:", req.user?.id);

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

    const order = addClientAlias({
      ...orderRes.rows[0],
      listing_reference_code: listing.reference_code,
    });

    // Send notification emails (non-blocking but awaited for consistency)
    const buyerEmailRes = await db.query("SELECT email FROM clients WHERE id = $1", [req.user.id]);
    const sellerEmailRes = await db.query("SELECT email FROM sellers WHERE id = $1", [listing.seller_id]);

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

const getClientOrders = async (buyerId) => {
  const result = await db.query(
      `SELECT o.*, COALESCE(l.title, 'Annonce supprimée') AS listing_title, l.reference_code AS listing_reference_code
       FROM orders o
       LEFT JOIN listings l ON o.listing_id = l.id
       WHERE o.buyer_id = $1
       ORDER BY o.created_at DESC`,
      [buyerId]
    );

    return result.rows.map(addClientAlias);
  };

  /**
   * GET /api/orders/buyer
   */
  router.get("/buyer", authRequired, requireRole("client"), async (req, res) => {
    try {
      const orders = await getClientOrders(req.user.id);
      res.json(orders);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Erreur serveur" });
    }
  });

  /**
   * GET /api/orders/me/client
   */
router.get("/me/client", authRequired, requireRole("client"), async (req, res) => {
  try {
    const orders = await getClientOrders(req.user.id);
    res.json(orders);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

  // Legacy buyer route kept for backward compatibility
  router.get("/me/buyer", authRequired, requireRole("client"), async (req, res) => {
    try {
      const orders = await getClientOrders(req.user.id);
      res.json(orders);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

  /**
   * GET /api/orders/seller
   */
  router.get("/seller", authRequired, requireRole("seller"), async (req, res) => {
    try {
      const result = await db.query(
        `SELECT o.*, COALESCE(l.title, 'Annonce supprimée') AS listing_title, l.reference_code AS listing_reference_code
         FROM orders o
         LEFT JOIN listings l ON o.listing_id = l.id
         WHERE o.seller_id = $1
         ORDER BY o.created_at DESC`,
        [req.user.id]
      );
      res.json(result.rows.map(addClientAlias));
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Erreur serveur" });
    }
  });

  /**
   * GET /api/orders/me/seller
   */
router.get("/me/seller", authRequired, requireRole("seller"), async (req, res) => {
  try {
    const result = await db.query(
      `SELECT o.*, COALESCE(l.title, 'Annonce supprimée') AS listing_title, l.reference_code AS listing_reference_code
       FROM orders o
       LEFT JOIN listings l ON o.listing_id = l.id
       WHERE o.seller_id = $1
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows.map(addClientAlias));
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
      "delivred",
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
      expidée: "shipped",
      expidee: "shipped",
      expedie: "shipped",
      expediee: "shipped",
      expédiee: "shipped",
      delivered: "delivred",
      delivery: "delivred",
      livré: "delivred",
      livree: "delivred",
      livrée: "delivred",
      livrer: "delivred",
      livret: "delivred",
      recu: "received",
      reçu: "received",
      recue: "received",
      reçue: "received",
      livre: "delivred",
      refus_de_reception: "reception_refused",
      "refus de reception": "reception_refused",
      "refus_de_réception": "reception_refused",
      "refus de réception": "reception_refused",
      done: "completed",
      en_attente: "pending",
      "en attente": "pending",
      confirmée: "confirmed",
      confirmee: "confirmed",
      refusée: "cancelled",
      refusee: "cancelled",
      "refusé": "cancelled",
      "refuse": "cancelled",
      expédiée: "shipped",
      expediee: "shipped",
      "à retirer": "ready_for_pickup",
      a_retirer: "ready_for_pickup",
      "a retirer": "ready_for_pickup",
      retirée: "picked_up",
      retiree: "picked_up",
      terminee: "completed",
      terminée: "completed",
      annulée: "cancelled",
      annulee: "cancelled",
    };

    const rawStatus = status ? String(status).toLowerCase() : "";
    const normalizedStatus = statusAliases[rawStatus] || rawStatus;

    if (!allowedStatuses.includes(normalizedStatus)) {
      return res.status(400).json({ message: "Statut invalide" });
    }

    const check = await db.query(
      "SELECT seller_id, buyer_id, status AS current_status, reception_mode FROM orders WHERE id = $1",
      [orderId]
    );
    const found = check.rows[0];
    if (!found) return res.status(404).json({ message: "Commande introuvable" });

    const normalizedReceptionMode = (found.reception_mode || "").toLowerCase();

    const isSeller = found.seller_id === req.user.id;
    const isBuyer = found.buyer_id === req.user.id;

    // Prevent cancelling orders unless they are still pending or confirmed
    const cancellableStatuses = [
      "pending",
      "confirmed",
      "shipped",
      "ready_for_pickup",
    ];
    if (
      normalizedStatus === "cancelled" &&
      !cancellableStatuses.includes(found.current_status)
    ) {
      return res
        .status(403)
        .json({ message: "Vous ne pouvez pas annuler cette commande" });
    }

  const workflow = {
    pending: { seller: ["confirmed", "cancelled"], buyer: ["cancelled"] },
    confirmed: {
      seller:
        normalizedReceptionMode === "retrait"
          ? ["ready_for_pickup", "cancelled"]
          : ["shipped", "cancelled"],
      buyer: [],
    },
    shipped: {
      seller: ["delivred", "reception_refused", "cancelled"],
      buyer: ["received", "reception_refused"],
    },
    delivred: {
      seller: ["completed", "reception_refused"],
      buyer: ["reception_refused"],
    },
    ready_for_pickup: { seller: ["picked_up", "cancelled"], buyer: [] },
    picked_up: { seller: ["completed"], buyer: [] },
    received: { seller: ["completed"], buyer: [] },
      reception_refused: { seller: [], buyer: [] },
      cancelled: { seller: [], buyer: [] },
      completed: { seller: [], buyer: [] },
    };

    const currentWorkflow = workflow[found.current_status];

    if (!currentWorkflow) {
      return res.status(400).json({ message: "Statut actuel inconnu" });
    }

    const allowedForUser = [
      ...(isSeller ? currentWorkflow.seller : []),
      ...(isBuyer ? currentWorkflow.buyer : []),
    ];

    if (!allowedForUser.includes(normalizedStatus)) {
      return res.status(403).json({ message: "Vous ne pouvez pas modifier cette commande" });
    }

    const result = await db.query(
      `UPDATE orders
       SET status = $1,
           updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [normalizedStatus, orderId]
    );

    res.json(addClientAlias(result.rows[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
