const colorModel = require("../models/colorModel");

const getAvailableColors = async () => {
  return colorModel.findAll();
};

const normalizeColors = async (colors) => {
  if (!Array.isArray(colors) || colors.length === 0) {
    return [];
  }

  const available = await colorModel.findAll();
  const availableByLower = new Map(
    available.map((color) => [color.name.toLowerCase(), color])
  );

  const normalized = [];
  const seen = new Set();

  for (const color of colors) {
    const key = String(color).trim().toLowerCase();
    if (!key) continue;

    const match = availableByLower.get(key);
    if (!match) {
      const availableNames = available.map((c) => c.name).join(", ");
      const err = new Error(
        `La couleur "${color}" n'est pas disponible. Couleurs autorisées : ${availableNames}.`
      );
      err.statusCode = 400;
      throw err;
    }

    if (!seen.has(match.name)) {
      normalized.push(match.name);
      seen.add(match.name);
    }
  }

  return normalized;
};

module.exports = {
  getAvailableColors,
  normalizeColors,
};
