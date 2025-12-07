const adService = require("../services/adService");

const createAd = async (req, res) => {
  try {
    const { title, category_id: categoryId, size_id: sizeId, price } = req.body;

    if (!title || !categoryId || !sizeId || price === undefined) {
      return res.status(400).json({
        message: "Champs requis: title, category_id, size_id, price",
      });
    }

    const parsedCategoryId = Number(categoryId);
    const parsedSizeId = Number(sizeId);
    const parsedPrice = Number(price);

    if (!Number.isInteger(parsedCategoryId) || parsedCategoryId <= 0) {
      return res.status(400).json({ message: "category_id invalide" });
    }

    if (!Number.isInteger(parsedSizeId) || parsedSizeId <= 0) {
      return res.status(400).json({ message: "size_id invalide" });
    }

    if (Number.isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ message: "price invalide" });
    }

    const ad = await adService.createAd({
      title: title.trim(),
      categoryId: parsedCategoryId,
      sizeId: parsedSizeId,
      price: parsedPrice,
    });

    return res.status(201).json(ad);
  } catch (err) {
    if (err.code === "SIZE_CATEGORY_MISMATCH") {
      return res.status(400).json({ message: "Cette taille n'est pas autorisée pour cette catégorie" });
    }

    console.error("Erreur lors de la création de l'annonce", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

const listAds = async (req, res) => {
  try {
    const { category_id: categoryId, size_id: sizeId } = req.query;

    const parsedCategoryId = categoryId ? Number(categoryId) : null;
    const parsedSizeId = sizeId ? Number(sizeId) : null;

    if (categoryId && (!Number.isInteger(parsedCategoryId) || parsedCategoryId <= 0)) {
      return res.status(400).json({ message: "category_id invalide" });
    }

    if (sizeId && (!Number.isInteger(parsedSizeId) || parsedSizeId <= 0)) {
      return res.status(400).json({ message: "size_id invalide" });
    }

    const ads = await adService.listAds({
      categoryId: parsedCategoryId,
      sizeId: parsedSizeId,
    });

    return res.json(ads);
  } catch (err) {
    console.error("Erreur lors du filtrage des annonces", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

module.exports = {
  createAd,
  listAds,
};
