const db = require("../db");

const findAll = async () => {
  const { rows } = await db.query(
    "SELECT id, name, hex_code FROM colors ORDER BY name ASC"
  );

  return rows;
};

module.exports = {
  findAll,
};
