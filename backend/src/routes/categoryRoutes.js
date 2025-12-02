// src/routes/categoryRoutes.js
const express = require("express");
const db = require("../db");

const router = express.Router();

const buildCategoryTree = (rows) => {
  const nodes = rows.map((row) => ({ ...row, children: [] }));
  const byId = new Map();
  nodes.forEach((node) => byId.set(node.id, node));

  const roots = [];
  nodes.forEach((node) => {
    if (node.parent_id) {
      const parent = byId.get(node.parent_id);
      if (parent) {
        parent.children.push(node);
      } else {
        roots.push(node);
      }
    } else {
      roots.push(node);
    }
  });

  return roots;
};

router.get("/tree", async (_req, res) => {
  try {
    const result = await db.query(
      "SELECT id, name, slug, parent_id FROM categories ORDER BY id"
    );

    const tree = buildCategoryTree(result.rows);

    res.json(tree);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;
