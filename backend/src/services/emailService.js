// src/services/emailService.js
// Simple mailer wrapper for order notifications.
const nodemailer = require("nodemailer");
require("dotenv").config();

let transporter = null;
if (process.env.SMTP_HOST) {
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: Boolean(process.env.SMTP_SECURE === "true"),
    auth: process.env.SMTP_USER
      ? {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        }
      : undefined,
  });
}

async function sendMail({ to, subject, html }) {
  if (!transporter) {
    console.warn("SMTP non configuré, email non envoyé", { to, subject });
    return;
  }

  await transporter.sendMail({
    from: process.env.MAIL_FROM || process.env.SMTP_USER,
    to,
    subject,
    html,
  });
}

function orderSummaryHtml(order, listingTitle) {
  return `
    <h2>Commande #${order.id}</h2>
    <p><strong>Produit :</strong> ${listingTitle}</p>
    <p><strong>Quantité :</strong> ${order.quantity}</p>
    <p><strong>Couleur :</strong> ${order.color || "Non précisé"}</p>
    <p><strong>Taille :</strong> ${order.size || "Non précisé"}</p>
    <p><strong>Mode de réception :</strong> ${order.reception_mode}</p>
    ${order.reception_mode === "livraison" ? `<p><strong>Adresse :</strong> ${order.shipping_address || ""}</p>` : ""}
    ${order.reception_mode === "livraison" ? `<p><strong>Téléphone :</strong> ${order.phone || ""}</p>` : ""}
    <p><strong>Total :</strong> ${order.total_amount} TND</p>
    <p>Statut : ${order.status}</p>
  `;
}

async function notifyBuyer(order, listingTitle, buyerEmail) {
  await sendMail({
    to: buyerEmail,
    subject: `Confirmation de commande - ${listingTitle}`,
    html: orderSummaryHtml(order, listingTitle),
  });
}

async function notifySeller(order, listingTitle, sellerEmail) {
  await sendMail({
    to: sellerEmail,
    subject: `Nouvelle commande reçue - ${listingTitle}`,
    html: orderSummaryHtml(order, listingTitle),
  });
}

module.exports = {
  notifyBuyer,
  notifySeller,
};
