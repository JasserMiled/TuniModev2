// src/routes/authRoutes.js
const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const userModel = require("../models/userModel");
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

    const existingUser = await userModel.getUserByEmail(normalizedEmail);

    if (existingUser) {
      return res.status(409).json({ message: "Email déjà utilisé" });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    // ✅ INSERT COMPLET AVEC ROLE
    const user = await userModel.createUser({
      name,
      email: normalizedEmail,
      passwordHash,
      role,
      phone,
      address,
      storeName: role === "seller" ? businessName : null,
      businessId: null,
      profileName: role === "client" ? name : null,
      dateOfBirth: role === "client" ? dateOfBirth : null,
    });

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
    const user = await userModel.getUserByEmail(email, { includePassword: true });

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

    const user = await userModel.getUserById(req.user.id, { includePassword: true });
    if (!user) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }

    let newPasswordHash;

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

      newPasswordHash = await bcrypt.hash(new_password, 10);
    }

    const updatedUser = await userModel.updateUser(req.user.id, req.user.role, {
      name,
      address,
      email,
      phone,
      avatar_url,
      password_hash: newPasswordHash,
      business_name,
      profile_name: name,
      date_of_birth,
    });

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

    const user = await userModel.getUserById(userId);
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
    await userModel.deleteUserById(req.user.id);
    return res.json({ message: "Compte supprimé" });
  } catch (err) {
    console.error("Erreur lors de la suppression du compte", err);
    return res.status(500).json({ message: "Impossible de supprimer le compte" });
  }
});

router.verifyToken = verifyToken;
module.exports = router;
