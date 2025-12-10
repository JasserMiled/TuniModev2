"use client";

import { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Listing } from "@/src/models/Listing";
import { ApiService } from "@/src/services/api";
import { useSearch } from "@/src/context/SearchContext";
import AppHeader from "@/src/components/AppHeader";
import ListingsGrid from "@/src/components/ListingsGrid";

export default function SearchResultsPage() {
  const params = useSearchParams();
  const router = useRouter();
  const { setSearch, lastSearch } = useSearch();

  const [query, setQuery] = useState(
    params.get("query") ?? lastSearch.query ?? ""
  );

  const [results, setResults] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ✅ FETCH RESULTS EXACTEMENT COMME HOME
  useEffect(() => {
    const filters = { ...lastSearch, query: query ?? "" };
    setSearch(filters);

    setLoading(true);
    ApiService.fetchListings({ query: query || undefined })
      .then(setResults)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [query]);

  return (
    <main className="bg-white min-h-screen">
      {/* ✅ HEADER IDENTIQUE À HOME */}
      <AppHeader />

      {/* ✅ CONTENU IDENTIQUE À HOME (SANS BANNER) */}
      <section className="max-w-6xl mx-auto px-4 pt-10 pb-12 space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">
            Résultats de recherche
          </h1>
          <p className="text-sm text-neutral-600 mt-1">
            Résultats pour : <span className="font-semibold">{query}</span>
          </p>
        </div>

        {/* BARRE DE RECHERCHE (OPTIONNELLE) */}
        <div className="flex gap-3">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Recherche"
            className="flex-1 border rounded-lg px-3 py-2"
          />
          <button
            onClick={() =>
              router.push(`/search/results?query=${encodeURIComponent(query)}`)
            }
            className="px-4 py-2 bg-blue-600 text-white rounded-lg"
          >
            Mettre à jour
          </button>
        </div>

        {/* ✅ LOADING / ERROR */}
        {loading && <div className="py-6 text-neutral-600">Chargement...</div>}
        {error && <div className="py-6 text-red-600">{error}</div>}

        {/* ✅ GRID IDENTIQUE À HOME */}
        {!loading && !error && (
          <>
            {results.length === 0 ? (
              <p className="text-neutral-500 py-6">
                Aucun résultat trouvé.
              </p>
            ) : (
              <ListingsGrid
                listings={results}
                columns={{ base: 2, sm: 3, md: 4, lg: 5 }}
                rows={{ base: 2, sm: 2, md: 2, lg: 2 }}
              />
            )}
          </>
        )}
      </section>
    </main>
  );
}
