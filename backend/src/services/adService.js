const adModel = require("../models/adModel");
const sizeService = require("./sizeService");

const createAd = async ({ title, categoryId, sizeId, price }) => {
  const sizeValid = await sizeService.validateSizeForCategory(categoryId, sizeId);

  if (!sizeValid) {
    const error = new Error("Size not allowed for this category");
    error.code = "SIZE_CATEGORY_MISMATCH";
    throw error;
  }

  return adModel.insertAd({ title, categoryId, sizeId, price });
};

const listAds = async ({ categoryId, sizeId }) => {
  return adModel.findAds({ categoryId, sizeId });
};

module.exports = {
  createAd,
  listAds,
};
