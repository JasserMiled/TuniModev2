"use client";

import { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Listing } from "@/src/models/Listing";
import { ApiService } from "@/src/services/api";
import { useSearch } from "@/src/context/SearchContext";

export default function SearchResultsPage() {
  const params = useSearchParams();
  const router = useRouter();
  const { setSearch, lastSearch } = useSearch();
  const [query, setQuery] = useState(params.get("query") ?? lastSearch.query ?? "");
  const [results, setResults] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const filters = { ...lastSearch, query: query ?? "" };
    setSearch(filters);
    setLoading(true);
    ApiService.fetchListings({ query })
      .then(setResults)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [query]);

  return (
    <div className="max-w-6xl mx-auto px-4 py-8 space-y-4">
      <h1 className="text-2xl font-semibold">Résultats de recherche</h1>
      <div className="flex gap-3">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Recherche"
          className="flex-1 border rounded-lg px-3 py-2"
        />
        <button
          onClick={() => router.push(`/search/results?query=${encodeURIComponent(query)}`)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg"
        >
          Mettre à jour
        </button>
      </div>
      {loading && <p>Chargement...</p>}
      {error && <p className="text-red-600">{error}</p>}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
        {results.map((listing) => (
          <div
            key={listing.id}
            onClick={() => router.push(`/listings/${listing.id}`)}
            className="border rounded-xl p-3 shadow-sm hover:shadow cursor-pointer"
          >
            <div className="aspect-[4/3] bg-neutral-100 rounded-lg mb-2 overflow-hidden">
              <img src={listing.imageUrls?.[0] ?? "/placeholder.jpg"} alt={listing.title} className="w-full h-full object-cover" />
            </div>
            <h3 className="font-semibold">{listing.title}</h3>
            <p className="text-blue-600 font-semibold">{listing.price} DT</p>
          </div>
        ))}
      </div>
    </div>
  );
}
