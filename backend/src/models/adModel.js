const db = require("../db");

const insertAd = async ({ title, categoryId, sizeId, price }) => {
  const { rows } = await db.query(
    `INSERT INTO ads (title, category_id, size_id, price)
     VALUES ($1, $2, $3, $4)
     RETURNING id, title, category_id, size_id, price, created_at`,
    [title, categoryId, sizeId, price]
  );

  return rows[0];
};

const findAds = async ({ categoryId, sizeId }) => {
  const conditions = [];
  const params = [];
  let idx = 1;

  if (categoryId) {
    conditions.push(`a.category_id = $${idx}`);
    params.push(categoryId);
    idx += 1;
  }

  if (sizeId) {
    conditions.push(`a.size_id = $${idx}`);
    params.push(sizeId);
    idx += 1;
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  const { rows } = await db.query(
    `SELECT a.id, a.title, a.category_id, a.size_id, a.price, a.created_at,
            s.label AS size_label,
            c.name AS category_name
     FROM ads a
     INNER JOIN sizes s ON s.id = a.size_id
     INNER JOIN categories c ON c.id = a.category_id
     ${whereClause}
     ORDER BY a.created_at DESC`,
    params
  );

  return rows;
};

module.exports = {
  insertAd,
  findAds,
};
