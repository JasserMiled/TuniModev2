const sizeModel = require("../models/sizeModel");

const getSizesForCategoryName = async (categoryName) => {
  if (!categoryName) {
    return [];
  }

  return sizeModel.findByCategoryName(categoryName);
};

const validateSizeForCategory = async (categoryId, sizeId) => {
  if (!categoryId || !sizeId) {
    return false;
  }

  return sizeModel.isSizeLinkedToCategory(categoryId, sizeId);
};

module.exports = {
  getSizesForCategoryName,
  validateSizeForCategory,
};
