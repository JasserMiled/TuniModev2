const db = require("../db");

const baseUserFields = [
  "u.id",
  "u.name",
  "u.email",
  "u.phone",
  "u.avatar_url",
  "u.address",
  "u.role",
  "u.created_at",
].join(", ");

const sellerFields = [
  "COALESCE(s.store_name, u.business_name) AS business_name",
  "COALESCE(s.business_id, u.business_id) AS business_id",
  "COALESCE(s.phone, u.phone) AS seller_phone",
  "COALESCE(s.address, u.address) AS seller_address",
  "COALESCE(s.avatar_url, u.avatar_url) AS seller_avatar_url",
  "s.created_at AS seller_created_at",
];

const clientFields = [
  "COALESCE(c.profile_name, u.name) AS profile_name",
  "COALESCE(c.date_of_birth, u.date_of_birth) AS date_of_birth",
  "COALESCE(c.phone, u.phone) AS client_phone",
  "COALESCE(c.address, u.address) AS client_address",
  "COALESCE(c.avatar_url, u.avatar_url) AS client_avatar_url",
  "c.created_at AS client_created_at",
];

const withJoins = `
  FROM users u
  LEFT JOIN sellers s ON s.user_id = u.id
  LEFT JOIN clients c ON c.user_id = u.id
`;

function buildSelect({ includePassword = false } = {}) {
  const passwordField = includePassword ? ", u.password_hash" : "";
  return `SELECT ${baseUserFields}, ${sellerFields.join(", ")}, ${clientFields.join(", ")} ${passwordField}`;
}

async function getUserByEmail(email, options = {}) {
  const query = `${buildSelect(options)} ${withJoins} WHERE LOWER(u.email) = LOWER($1)`;
  const { rows } = await db.query(query, [email]);
  return rows[0];
}

async function getUserById(userId, options = {}) {
  const query = `${buildSelect(options)} ${withJoins} WHERE u.id = $1`;
  const { rows } = await db.query(query, [userId]);
  return rows[0];
}

async function listUsers(limit = 100) {
  const query = `${buildSelect()} ${withJoins} ORDER BY u.created_at DESC LIMIT $1`;
  const { rows } = await db.query(query, [limit]);
  return rows;
}

async function upsertSellerProfile(userId, { storeName, businessId, phone, address, avatarUrl }) {
  await db.query(
    `INSERT INTO sellers (user_id, store_name, business_id, phone, address, avatar_url)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (user_id) DO UPDATE SET
       store_name = COALESCE(EXCLUDED.store_name, sellers.store_name),
       business_id = COALESCE(EXCLUDED.business_id, sellers.business_id),
       phone = COALESCE(EXCLUDED.phone, sellers.phone),
       address = COALESCE(EXCLUDED.address, sellers.address),
       avatar_url = COALESCE(EXCLUDED.avatar_url, sellers.avatar_url),
       updated_at = NOW()`.
      replace(/\s+/g, " "),
    [userId, storeName || null, businessId || null, phone || null, address || null, avatarUrl || null]
  );

  // Keep deprecated columns aligned until the migration is complete.
  await db.query(
    `UPDATE users
     SET business_name = COALESCE($2, business_name),
         business_id = COALESCE($3, business_id)
     WHERE id = $1`,
    [userId, storeName || null, businessId || null]
  );
}

async function upsertClientProfile(userId, { profileName, dateOfBirth, phone, address, avatarUrl }) {
  await db.query(
    `INSERT INTO clients (user_id, profile_name, date_of_birth, phone, address, avatar_url)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (user_id) DO UPDATE SET
       profile_name = COALESCE(EXCLUDED.profile_name, clients.profile_name),
       date_of_birth = COALESCE(EXCLUDED.date_of_birth, clients.date_of_birth),
       phone = COALESCE(EXCLUDED.phone, clients.phone),
       address = COALESCE(EXCLUDED.address, clients.address),
       avatar_url = COALESCE(EXCLUDED.avatar_url, clients.avatar_url),
       updated_at = NOW()`.
      replace(/\s+/g, " "),
    [userId, profileName || null, dateOfBirth || null, phone || null, address || null, avatarUrl || null]
  );

  await db.query(
    `UPDATE users
     SET date_of_birth = COALESCE($2, date_of_birth)
     WHERE id = $1`,
    [userId, dateOfBirth || null]
  );
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
  profileName,
  dateOfBirth,
}) {
  const normalizedEmail = String(email).toLowerCase();
  const { rows } = await db.query(
    `INSERT INTO users (name, email, password_hash, role, phone, address, avatar_url, business_name, business_id, date_of_birth)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING id`,
    [
      name,
      normalizedEmail,
      passwordHash,
      role,
      phone,
      address || null,
      avatarUrl || null,
      role === "seller" ? storeName || null : null,
      role === "seller" ? businessId || null : null,
      role === "client" ? dateOfBirth || null : null,
    ]
  );

  const userId = rows[0].id;

  if (role === "seller") {
    await upsertSellerProfile(userId, {
      storeName,
      businessId,
      phone,
      address,
      avatarUrl,
    });
  } else if (role === "client") {
    await upsertClientProfile(userId, {
      profileName: profileName || name,
      dateOfBirth,
      phone,
      address,
      avatarUrl,
    });
  }

  return getUserById(userId);
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

  if (updates.length) {
    values.push(userId);
    const query = `UPDATE users SET ${updates.join(", ")} WHERE id = $${idx} RETURNING id`;
    await db.query(query, values);
  }

  if (role === "seller") {
    await upsertSellerProfile(userId, {
      storeName: business_name,
      businessId: business_id,
      phone,
      address,
      avatarUrl: avatar_url,
    });
  } else if (role === "client") {
    await upsertClientProfile(userId, {
      profileName: profile_name || name,
      dateOfBirth: date_of_birth,
      phone,
      address,
      avatarUrl: avatar_url,
    });
  }

  return getUserById(userId);
}

async function deleteUserById(userId) {
  await db.query("DELETE FROM users WHERE id = $1", [userId]);
}

module.exports = {
  createUser,
  deleteUserById,
  getUserByEmail,
  getUserById,
  listUsers,
  updateUser,
};
