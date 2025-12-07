// Exemple simple de mise à jour dynamique des tailles côté front
// À intégrer dans une page disposant de deux listes déroulantes :
// <select id="categorySelect"></select> et <select id="sizeSelect"></select>

async function refreshSizes() {
  const categorySelect = document.getElementById("categorySelect");
  const sizeSelect = document.getElementById("sizeSelect");
  const categoryName = categorySelect?.value;

  if (!categoryName) {
    sizeSelect.innerHTML = "";
    return;
  }

  const response = await fetch(`/api/sizes?category=${encodeURIComponent(categoryName)}`);
  const sizes = await response.json();

  sizeSelect.innerHTML = "";
  sizes.forEach((size) => {
    const option = document.createElement("option");
    option.value = size.id;
    option.textContent = size.label;
    sizeSelect.appendChild(option);
  });
}

document.getElementById("categorySelect")?.addEventListener("change", refreshSizes);
