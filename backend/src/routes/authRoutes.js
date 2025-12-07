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
// Inscription d'un utilisateur avec hash du mot de passe
router.post("/register", async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ message: "Nom, email et mot de passe requis" });
  }

  try {
    const existingUser = await db.query("SELECT 1 FROM users WHERE email = $1", [email]);
    if (existingUser.rows.length) {
      return res.status(409).json({ message: "Email déjà utilisé" });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const insertResult = await db.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, email`,
      [name, email, passwordHash, "buyer"]
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
      "SELECT id, name, email, password_hash, role FROM users WHERE email = $1",
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

    const updateQuery = `UPDATE users SET ${updates.join(", ")} WHERE id = $${index} RETURNING id, name, email, phone, avatar_url, address, role`;
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
      "SELECT id, name, email, phone, avatar_url, address, role FROM users WHERE id = $1",
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

router.verifyToken = verifyToken;
module.exports = router;
