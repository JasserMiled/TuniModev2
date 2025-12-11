// src/routes/authRoutes.js
const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../db");
require("dotenv").config();

const router = express.Router();

// Middleware pour vérifier et décoder un token JWT
function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization || "";
  const [scheme, token] = authHeader.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ message: "Token manquant ou invalide" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    console.error("JWT verification failed", err);
    return res.status(401).json({ message: "Token invalide" });
  }
}

// POST /api/auth/register
// Inscription d'un utilisateur avec hash du mot de passe, réponse compatible Flutter Web
// POST /api/auth/register
router.post("/register", async (req, res) => {
  const {
    name,
    email,
    password,
    role,
    phone,
    address,
    businessName,
    dateOfBirth,
  } = req.body || {};

  // ✅ Vérifications obligatoires communes
  if (!name || !email || !password || !role || !phone) {
    return res.status(400).json({
      message: "Nom, email, téléphone, mot de passe et rôle sont requis",
    });
  }

  // ✅ Règles spécifiques au rôle
  if (role === "seller" && !businessName) {
    return res.status(400).json({ message: "Le nom de la boutique est requis" });
  }

  if (role === "client" && !dateOfBirth) {
    return res.status(400).json({ message: "La date de naissance est requise" });
  }

  // ✅ Sécurité sur les rôles autorisés
  const allowedRoles = ["seller", "client"];
  if (!allowedRoles.includes(role)) {
    return res.status(400).json({ message: "Rôle invalide" });
  }

  try {
    const normalizedEmail = String(email).toLowerCase();

    const existingUser = await db.query(
      "SELECT 1 FROM users WHERE email = $1",
      [normalizedEmail]
    );

    if (existingUser.rows.length) {
      return res.status(409).json({ message: "Email déjà utilisé" });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    // ✅ INSERT COMPLET AVEC ROLE
    const insertResult = await db.query(
      `INSERT INTO users (name, email, password_hash, role, phone, address, business_name, date_of_birth)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, name, email, role, phone, address, business_name, date_of_birth`,
      [
        name,
        normalizedEmail,
        passwordHash,
        role, // ✅ IMPORTANT
        phone,
        address || null,
        businessName || null,
        dateOfBirth || null,
      ]
    );

    const user = insertResult.rows[0];
    return res.status(201).json(user);
  } catch (err) {
    console.error("Error during registration", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
});


// POST /api/auth/login
// Authentifie l'utilisateur et génère un token JWT valable 1h
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email et mot de passe requis" });
  }

  try {
    const result = await db.query(
      `SELECT id, name, email, phone, address, business_name, date_of_birth, password_hash, role
       FROM users WHERE email = $1`,
      [email]
    );
    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ message: "Identifiants invalides" });
    }

    const passwordMatches = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ message: "Identifiants invalides" });
    }

    const tokenPayload = { id: user.id, email: user.email, role: user.role };
    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, { expiresIn: "1h" });

    const { password_hash: _passwordHash, ...safeUser } = user;
    return res.json({ user: safeUser, token });
  } catch (err) {
    console.error("Error during login", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
});

// PUT /api/auth/me
// Permet à l'utilisateur connecté de mettre à jour ses informations de compte
router.put("/me", verifyToken, async (req, res) => {
  try {
    const {
      name,
      address,
      email,
      phone,
      current_password,
      new_password,
      avatar_url,
      business_name,
      date_of_birth,
    } = req.body;

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

    if (business_name !== undefined) {
      updates.push(`business_name = $${index++}`);
      values.push(business_name || null);
    }

    if (date_of_birth !== undefined) {
      updates.push(`date_of_birth = $${index++}`);
      values.push(date_of_birth || null);
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

    const updateQuery = `UPDATE users SET ${updates.join(", ")} WHERE id = $${index} RETURNING id, name, email, phone, avatar_url, address, role, business_name, date_of_birth`;
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

// GET /api/auth/user/:id
// Récupère les informations publiques d'un utilisateur
router.get("/user/:id", async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({ message: "Identifiant utilisateur invalide" });
    }

    const result = await db.query(
      `SELECT id, name, email, phone, avatar_url, address, role, business_name, date_of_birth
       FROM users WHERE id = $1`,
      [userId]
    );

    const user = result.rows[0];
    if (!user) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }

    return res.json({ user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

// DELETE /api/auth/me
// Permet à l'utilisateur connecté de supprimer définitivement son compte
router.delete("/me", verifyToken, async (req, res) => {
  try {
    await db.query("DELETE FROM users WHERE id = $1", [req.user.id]);
    return res.json({ message: "Compte supprimé" });
  } catch (err) {
    console.error("Erreur lors de la suppression du compte", err);
    return res.status(500).json({ message: "Impossible de supprimer le compte" });
  }
});

router.verifyToken = verifyToken;
module.exports = router;
