const db = require("../db");

const findByCategoryName = async (categoryName) => {
  const { rows } = await db.query(
    `SELECT s.id, s.label
     FROM sizes s
     INNER JOIN category_sizes cs ON cs.size_id = s.id
     INNER JOIN categories c ON c.id = cs.category_id
     WHERE LOWER(c.name) = LOWER($1)
     ORDER BY s.label`,
    [categoryName]
  );

  return rows;
};

const isSizeLinkedToCategory = async (categoryId, sizeId) => {
  const { rowCount } = await db.query(
    `SELECT 1
     FROM category_sizes
     WHERE category_id = $1 AND size_id = $2`,
    [categoryId, sizeId]
  );

  return rowCount > 0;
};

module.exports = {
  findByCategoryName,
  isSizeLinkedToCategory,
};
