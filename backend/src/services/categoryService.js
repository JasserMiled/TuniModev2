// src/services/categoryService.js
// Service utilitaire pour récupérer les catégories descendantes et filtrer les produits.

const db = require("../db");

/**
 * Retourne un tableau contenant l'identifiant fourni ainsi que tous ses
 * descendants directs et indirects. Utilise un CTE récursif pour éviter
 * les requêtes N+1 et supporter une profondeur de hiérarchie illimitée.
 *
 * @param {number} categoryId
 * @returns {Promise<number[]>}
 */
const getCategoryWithChildren = async (categoryId) => {
  if (!categoryId) {
    throw new Error("categoryId est requis");
  }

  const { rows } = await db.query(
    `WITH RECURSIVE category_tree AS (
       SELECT id, parent_id
       FROM categories
       WHERE id = $1
       UNION ALL
       SELECT c.id, c.parent_id
       FROM categories c
       INNER JOIN category_tree ct ON c.parent_id = ct.id
     )
     SELECT DISTINCT id
     FROM category_tree
     ORDER BY id`,
    [categoryId]
  );

  return rows.map((row) => row.id);
};

/**
 * Retourne l'ensemble des produits appartenant à une catégorie donnée
 * ainsi qu'à toutes ses sous-catégories, quelle que soit la profondeur
 * de la hiérarchie. La requête unique évite les allers-retours multiples
 * en base de données.
 *
 * @param {number} categoryId
 * @returns {Promise<object[]>}
 */
const filterProductsByCategory = async (categoryId) => {
  if (!categoryId) {
    throw new Error("categoryId est requis");
  }

  const { rows } = await db.query(
    `WITH RECURSIVE category_tree AS (
       SELECT id, parent_id
       FROM categories
       WHERE id = $1
       UNION ALL
       SELECT c.id, c.parent_id
       FROM categories c
       INNER JOIN category_tree ct ON c.parent_id = ct.id
     )
     SELECT p.*
     FROM products p
     WHERE p.category_id IN (SELECT DISTINCT id FROM category_tree)`,
    [categoryId]
  );

  return rows;
};

module.exports = {
  getCategoryWithChildren,
  filterProductsByCategory,
};
