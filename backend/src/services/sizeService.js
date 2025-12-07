const sizeModel = require("../models/sizeModel");

const getSizesForCategory = async ({ categoryId, categoryName }) => {
  if (categoryId) {
    return sizeModel.findByCategoryId(categoryId);
  }

  if (categoryName) {
    return sizeModel.findByCategoryName(categoryName);
  }

  return [];
};

const validateSizeForCategory = async (categoryId, sizeId) => {
  if (!categoryId || !sizeId) {
    return false;
  }

  return sizeModel.isSizeLinkedToCategory(categoryId, sizeId);
};

module.exports = {
  getSizesForCategory,
  validateSizeForCategory,
};
