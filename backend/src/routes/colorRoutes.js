const express = require("express");
const { getColors } = require("../controllers/colorController");

const router = express.Router();

router.get("/", getColors);

module.exports = router;
