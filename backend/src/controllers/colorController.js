const colorService = require("../services/colorService");

const getColors = async (_req, res) => {
  try {
    const colors = await colorService.getAvailableColors();
    return res.json(colors);
  } catch (err) {
    console.error("Erreur lors de la récupération des couleurs", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

module.exports = {
  getColors,
};
