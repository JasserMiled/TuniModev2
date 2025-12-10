// src/routes/uploadRoutes.js
const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { authRequired } = require("../middleware/auth");

const router = express.Router();

const uploadDir = path.join(__dirname, "..", "..", "uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, unique + ext);
  },
});

const upload = multer({ storage });

router.post("/image", authRequired, upload.single("image"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "Aucun fichier" });
  }
  const relativeUrl = "/uploads/" + req.file.filename;
  const host = req.get("host");
  const absoluteUrl = host
    ? `${req.protocol}://${host}${relativeUrl}`
    : relativeUrl;
  res.status(201).json({ url: absoluteUrl, path: relativeUrl });
});

module.exports = router;
