const sizeService = require("../services/sizeService");

const getSizes = async (req, res) => {
  try {
    const { category, category_id: categoryId } = req.query;
    const parsedCategoryId = categoryId !== undefined ? Number(categoryId) : null;

    if (!category && !categoryId) {
      return res
        .status(400)
        .json({ message: "Paramètre category ou category_id obligatoire" });
    }

    if (categoryId !== undefined && (!Number.isInteger(parsedCategoryId) || parsedCategoryId <= 0)) {
      return res.status(400).json({ message: "category_id invalide" });
    }

    const sizes = await sizeService.getSizesForCategory({
      categoryId: parsedCategoryId,
      categoryName: category,
    });
    return res.json(sizes);
  } catch (err) {
    console.error("Erreur lors de la récupération des tailles", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

module.exports = {
  getSizes,
};
