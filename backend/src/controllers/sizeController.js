const sizeService = require("../services/sizeService");

const getSizes = async (req, res) => {
  try {
    const { category } = req.query;

    if (!category) {
      return res.status(400).json({ message: "Paramètre category obligatoire" });
    }

    const sizes = await sizeService.getSizesForCategoryName(category);
    return res.json(sizes);
  } catch (err) {
    console.error("Erreur lors de la récupération des tailles", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

module.exports = {
  getSizes,
};
