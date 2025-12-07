const express = require("express");
const { getSizes } = require("../controllers/sizeController");

const router = express.Router();

router.get("/", getSizes);

module.exports = router;
