// src/middleware/auth.js
const jwt = require("jsonwebtoken");
require("dotenv").config();

// Authenticate requests by validating JWT tokens sent via the Authorization header.
function authRequired(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Token manquant" });
  }
  const token = authHeader.substring(7);

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const allowedRoles = ["seller", "client"];
    if (!allowedRoles.includes(payload.role)) {
      return res.status(403).json({ message: "Accès refusé" });
    }
    req.user = payload; // { id, role }
    next();
  } catch (err) {
    return res.status(401).json({ message: "Token invalide" });
  }
}

function requireRole(...roles) {
  // Wrap authorization logic so individual routes can easily restrict access
  // to the roles they need without duplicating checks.
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ message: "Accès refusé" });
    }
    next();
  };
}

module.exports = { authRequired, requireRole };
