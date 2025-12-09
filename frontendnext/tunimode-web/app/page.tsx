"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { fetchListings } from "@/lib/api";

type Listing = {
  id: number;
  title: string;
  price: number;
  images: string[];
};

export default function HomePage() {
  const router = useRouter();
  const [listings, setListings] = useState<Listing[]>([]);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetchListings()
      .then(setListings)
      .catch(() => setError("Erreur de chargement"))
      .finally(() => setLoading(false));
  }, []);

  const latestListings = listings.slice(0, 10);

  const handleSearch = () => {
    if (!query.trim()) return;
    router.push(`/search?q=${query}`);
  };

  return (
    <main className="bg-white min-h-screen px-4">

      {/* ✅ HERO BANNER (IDENTIQUE À FLUTTER) */}
      <section className="max-w-7xl mx-auto pt-6">
        <div className="relative h-[500px] w-full rounded-2xl overflow-hidden">
          <img
            src="/banner.jpg"
            className="w-full h-full object-cover"
            alt="Hero"
          />

          {/* ✅ GRADIENT */}
          <div className="absolute inset-0 bg-gradient-to-tr from-black/50 to-black/10" />

          {/* ✅ TEXTE + BOUTONS */}
          <div className="absolute bottom-8 left-8 max-w-xl text-white space-y-4">
            <div className="inline-block px-3 py-1 bg-white/10 border border-white/30 rounded-md text-xs font-bold">
              Plateforme n°1 de mode circulaire en Tunisie
            </div>

            <h1 className="text-3xl font-extrabold leading-tight">
              Découvre les dernières trouvailles sélectionnées pour toi
            </h1>

            <div className="flex gap-3">
              <button
                onClick={handleSearch}
                className="bg-blue-600 px-5 py-3 rounded-xl font-semibold"
              >
                Explorer
              </button>

              <button className="border border-white/70 px-5 py-3 rounded-xl">
                Filtres rapides
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ✅ SEARCH BAR COMME FLUTTER */}
      <section className="max-w-4xl mx-auto mt-8">
        <div className="flex items-center bg-white border rounded-2xl p-4 shadow gap-3">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Rechercher..."
            className="flex-1 outline-none text-lg"
          />
          <button
            onClick={handleSearch}
            className="bg-blue-600 text-white px-5 py-2 rounded-xl"
          >
            Chercher
          </button>
        </div>
      </section>

      {/* ✅ LISTINGS */}
      <section className="max-w-7xl mx-auto mt-14 pb-20">
        <h2 className="text-xl font-extrabold">
          Derniers articles mis en ligne
        </h2>

        <p className="text-gray-600 mb-6">
          Choisis tes prochaines trouvailles parmi des milliers de vêtements et accessoires.
        </p>

        {loading && <div className="text-center py-10">Chargement...</div>}
        {error && <div className="text-center text-red-600">{error}</div>}

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-6">
          {latestListings.map((listing) => (
            <div
              key={listing.id}
              onClick={() => router.push(`/listing/${listing.id}`)}
              className="bg-white rounded-xl shadow hover:shadow-lg transition cursor-pointer"
            >
              <img
                src={
                  listing.images?.[0]
                    ? `${process.env.NEXT_PUBLIC_API_BASE_URL}/uploads/${listing.images[0]}`
                    : "/placeholder.jpg"
                }
                className="w-full h-64 object-cover rounded-t-xl"
                alt={listing.title}
              />

              <div className="p-3">
                <p className="font-semibold text-sm line-clamp-2">
                  {listing.title}
                </p>
                <p className="text-blue-600 font-bold">
                  {listing.price} DT
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
