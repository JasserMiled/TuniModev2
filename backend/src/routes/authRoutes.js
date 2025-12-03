// src/routes/authRoutes.js
const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../db");
const { authRequired } = require("../middleware/auth");
require("dotenv").config();

const router = express.Router();

// POST /api/auth/register
router.post("/register", async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      phone,
      address,
      role,
      business_name,
      business_id,
    } = req.body;

    if (!["buyer", "pro"].includes(role)) {
      return res.status(400).json({ message: "Role invalide" });
    }

    const hashed = await bcrypt.hash(password, 10);

    const result = await db.query(
      `INSERT INTO users (name, email, password_hash, phone, avatar_url, address, role, business_name, business_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING id, name, email, phone, avatar_url, address, role`,
      [
        name,
        email,
        hashed,
        phone,
        null,
        address || null,
        role,
        business_name || null,
        business_id || null,
      ]
    );

    const user = result.rows[0];
    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.status(201).json({ user, token });
  } catch (err) {
    console.error(err);
    if (err.code === "23505") {
      return res.status(400).json({ message: "Email déjà utilisé" });
    }
    res.status(500).json({ message: "Erreur serveur" });
  }
});

// POST /api/auth/login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await db.query(
      "SELECT id, name, email, phone, avatar_url, address, password_hash, role FROM users WHERE email = $1",
      [email]
    );
    const user = result.rows[0];
    if (!user) return res.status(401).json({ message: "Identifiants invalides" });

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ message: "Identifiants invalides" });

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    delete user.password_hash;
    res.json({ user, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

// PUT /api/auth/me
// Permet à l'utilisateur connecté de mettre à jour ses informations de compte
router.put("/me", authRequired, async (req, res) => {
  try {
    const { name, address, email, phone, current_password, new_password, avatar_url } = req.body;

    const existingResult = await db.query(
      "SELECT id, name, email, phone, avatar_url, address, password_hash, role FROM users WHERE id = $1",
      [req.user.id]
    );
    const user = existingResult.rows[0];
    if (!user) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }

    const updates = [];
    const values = [];
    let index = 1;

    if (name !== undefined) {
      updates.push(`name = $${index++}`);
      values.push(name);
    }
    if (address !== undefined) {
      updates.push(`address = $${index++}`);
      values.push(address || null);
    }
    if (email !== undefined) {
      updates.push(`email = $${index++}`);
      values.push(email);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${index++}`);
      values.push(phone || null);
    }
    if (avatar_url !== undefined) {
      updates.push(`avatar_url = $${index++}`);
      values.push(avatar_url || null);
    }

    if (new_password) {
      if (!current_password) {
        return res
          .status(400)
          .json({ message: "Le mot de passe actuel est requis pour la modification." });
      }

      const passwordMatches = await bcrypt.compare(current_password, user.password_hash);
      if (!passwordMatches) {
        return res.status(400).json({ message: "Mot de passe actuel incorrect" });
      }

      const hashed = await bcrypt.hash(new_password, 10);
      updates.push(`password_hash = $${index++}`);
      values.push(hashed);
    }

    if (!updates.length) {
      const { password_hash, ...safeUser } = user;
      return res.json({ user: safeUser });
    }

    values.push(req.user.id);

    const updateQuery = `UPDATE users SET ${updates.join(", ")} WHERE id = $$${index} RETURNING id, name, email, phone, avatar_url, address, role`;
    const updateResult = await db.query(updateQuery, values);
    const updatedUser = updateResult.rows[0];

    return res.json({ user: updatedUser });
  } catch (err) {
    console.error(err);
    if (err.code === "23505") {
      return res.status(400).json({ message: "Email déjà utilisé" });
    }
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
