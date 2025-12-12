function formatDateToMMDDYY(dateInput) {
  const date = dateInput instanceof Date ? dateInput : new Date(dateInput);
  if (Number.isNaN(date.getTime())) {
    throw new Error("Invalid seller creation date");
  }
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  const yy = String(date.getFullYear()).slice(-2);
  return `${mm}${dd}${yy}`;
}

function generateListingReference(storeName, sellerId, sellerCreationDate, listingCount) {
  const storePart = (storeName || "").slice(0, 3).toUpperCase();
  const index = Number(listingCount ?? 0) + 1;
  const datePart = formatDateToMMDDYY(sellerCreationDate);
  return `TN${storePart}${sellerId}${datePart}_${index}`;
}

module.exports = {
  generateListingReference,
};
