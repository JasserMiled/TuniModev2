const express = require("express");
const { createAd, listAds } = require("../controllers/adController");

const router = express.Router();

router.get("/", listAds);
router.post("/", createAd);

module.exports = router;
