const db = require("../db");

const accountCte = `
  WITH accounts AS (
    SELECT
      s.id,
      s.name,
      s.email,
      s.password_hash,
      s.phone,
      s.avatar_url,
      s.address,
      'seller' AS role,
      s.store_name AS business_name,
      s.business_id,
      s.description,
      NULL::DATE AS date_of_birth,
      s.created_at
    FROM sellers s
    UNION ALL
    SELECT
      c.id,
      COALESCE(c.profile_name, c.name) AS name,
      c.email,
      c.password_hash,
      c.phone,
      c.avatar_url,
      c.address,
      'client' AS role,
      NULL::TEXT AS business_name,
      NULL::TEXT AS business_id,
      NULL::TEXT AS description,
      c.date_of_birth,
      c.created_at
    FROM clients c
  )
`;

const baseUserFields = [
  "a.id",
  "a.name",
  "a.email",
  "a.phone",
  "a.avatar_url",
  "a.address",
  "a.role",
  "a.created_at",
  "a.business_name",
  "a.business_id",
  "a.description",
  "a.date_of_birth",
].join(", ");

function buildSelect({ includePassword = false } = {}) {
  const passwordField = includePassword ? ", a.password_hash" : "";
  return `SELECT ${baseUserFields}${passwordField} FROM accounts a`;
}

async function getUserByEmail(email, options = {}) {
  const query = `${accountCte} ${buildSelect(options)} WHERE LOWER(a.email) = LOWER($1)`;
  const { rows } = await db.query(query, [email]);
  return rows[0];
}

async function getUserById(userId, options = {}) {
  const query = `${accountCte} ${buildSelect(options)} WHERE a.id = $1`;
  const { rows } = await db.query(query, [userId]);
  return rows[0];
}

async function listUsers(limit = 100) {
  const query = `${accountCte} ${buildSelect()} ORDER BY a.created_at DESC LIMIT $1`;
  const { rows } = await db.query(query, [limit]);
  return rows;
}

async function createUser({
  name,
  email,
  passwordHash,
  role,
  phone,
  address,
  avatarUrl,
  storeName,
  businessId,
  description,
  profileName,
  dateOfBirth,
}) {
  const normalizedEmail = String(email).toLowerCase();

  if (role === "seller") {
    const { rows } = await db.query(
      `INSERT INTO sellers (name, email, password_hash, phone, address, avatar_url, store_name, business_id, description)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id`,
      [
        name,
        normalizedEmail,
        passwordHash,
        phone,
        address || null,
        avatarUrl || null,
        storeName || null,
        businessId || null,
        description || null,
      ]
    );

    return getUserById(rows[0].id);
  }

  const { rows } = await db.query(
    `INSERT INTO clients (name, profile_name, email, password_hash, phone, address, avatar_url, date_of_birth)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING id`,
    [
      name,
      profileName || name,
      normalizedEmail,
      passwordHash,
      phone,
      address || null,
      avatarUrl || null,
      dateOfBirth || null,
    ]
  );

  return getUserById(rows[0].id);
}

async function updateUser(userId, role, {
  name,
  address,
  email,
  phone,
  avatar_url,
  password_hash,
  business_name,
  business_id,
  description,
  profile_name,
  date_of_birth,
}) {
  const updates = [];
  const values = [];
  let idx = 1;

  if (name !== undefined) {
    updates.push(`name = $${idx++}`);
    values.push(name);
  }
  if (address !== undefined) {
    updates.push(`address = $${idx++}`);
    values.push(address || null);
  }
  if (email !== undefined) {
    updates.push(`email = $${idx++}`);
    values.push(String(email).toLowerCase());
  }
  if (phone !== undefined) {
    updates.push(`phone = $${idx++}`);
    values.push(phone || null);
  }
  if (avatar_url !== undefined) {
    updates.push(`avatar_url = $${idx++}`);
    values.push(avatar_url || null);
  }
  if (password_hash !== undefined) {
    updates.push(`password_hash = $${idx++}`);
    values.push(password_hash);
  }

  const tableName = role === "seller" ? "sellers" : "clients";
  const roleSpecificUpdates = [...updates];

  if (role === "seller") {
    if (business_name !== undefined) {
      roleSpecificUpdates.push(`store_name = $${idx++}`);
      values.push(business_name || null);
    }
    if (business_id !== undefined) {
      roleSpecificUpdates.push(`business_id = $${idx++}`);
      values.push(business_id || null);
    }
    if (description !== undefined) {
      roleSpecificUpdates.push(`description = $${idx++}`);
      values.push(description || null);
    }
  } else if (role === "client") {
    if (profile_name !== undefined) {
      roleSpecificUpdates.push(`profile_name = $${idx++}`);
      values.push(profile_name || null);
    }
    if (date_of_birth !== undefined) {
      roleSpecificUpdates.push(`date_of_birth = $${idx++}`);
      values.push(date_of_birth || null);
    }
  }

  if (!roleSpecificUpdates.length) {
    return getUserById(userId);
  }

  values.push(userId);

  const query = `UPDATE ${tableName} SET ${roleSpecificUpdates.join(", ")}, updated_at = NOW() WHERE id = $${idx} RETURNING id`;
  await db.query(query, values);

  return getUserById(userId);
}

async function deleteUserById(userId) {
  const user = await getUserById(userId);
  if (!user) return;

  const tableName = user.role === "seller" ? "sellers" : "clients";
  await db.query(`DELETE FROM ${tableName} WHERE id = $1`, [userId]);
}

module.exports = {
  createUser,
  deleteUserById,
  getUserByEmail,
  getUserById,
  listUsers,
  updateUser,
};
