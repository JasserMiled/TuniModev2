const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL;

export async function fetchListings(params = {}) {
  const query = new URLSearchParams(
    Object.entries(params).reduce((acc, [k, v]) => {
      if (v !== undefined && v !== null && v !== "") {
        acc[k] = String(v);
      }
      return acc;
    }, {})
  );

  const res = await fetch(`${API_BASE}/api/listings?${query.toString()}`); // ✅ SANS credentials

  if (!res.ok) {
    throw new Error("Failed to fetch listings");
  }

  return res.json();
}

