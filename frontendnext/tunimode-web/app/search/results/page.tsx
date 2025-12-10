"use client";

import { useCallback, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Listing } from "@/src/models/Listing";
import { ApiService } from "@/src/services/api";
import { SearchFilters, useSearch } from "@/src/context/SearchContext";
import AppHeader from "@/src/components/AppHeader";
import ListingsGrid from "@/src/components/ListingsGrid";
import {
  buildResultsUrl,
  filtersFromParams,
  toApiFilterParams,
} from "@/src/utils/searchFilters";

export default function SearchResultsPage() {
  const params = useSearchParams();
  const router = useRouter();
  const { setSearch, lastSearch } = useSearch();

  const paramsString = params.toString();

  const buildFilters = useCallback(
    () => filtersFromParams(params, lastSearch),
    [paramsString, lastSearch]
  );

  const [filters, setFilters] = useState<SearchFilters>(buildFilters);
  const [queryInput, setQueryInput] = useState(filters.query ?? "");

  const [results, setResults] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const nextFilters = buildFilters();
    setFilters((prev) => {
      const same = JSON.stringify(prev) === JSON.stringify(nextFilters);
      return same ? prev : nextFilters;
    });
    setQueryInput(nextFilters.query ?? "");
  }, [buildFilters]);

  useEffect(() => {
    const requestFilters = toApiFilterParams(filters);
    setSearch(filters);

    setLoading(true);
    setError(null);

    ApiService.fetchListings(requestFilters)
      .then(setResults)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [filters, setSearch]);

  const handleQuerySubmit = () => {
    const trimmedQuery = queryInput.trim();
    const nextFilters = { ...filters, query: trimmedQuery };
    setFilters(nextFilters);
    setSearch(nextFilters);
    router.push(buildResultsUrl(nextFilters));
  };

  return (
    <main className="bg-white min-h-screen">
      <AppHeader />

      <section className="max-w-6xl mx-auto px-4 pt-10 pb-12 space-y-6">
        <div className="space-y-1">
          <h1 className="text-2xl font-bold text-neutral-900">
            Résultats de recherche
          </h1>
          <p className="text-sm text-neutral-600">
            Résultats pour : <span className="font-semibold">{filters.query}</span>
          </p>
        </div>

        <div className="bg-neutral-50 border border-neutral-200 rounded-xl px-4 py-3 shadow-sm">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="relative flex-1 min-w-0">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400">
                🔍
              </span>
              <input
                value={queryInput}
                onChange={(e) => setQueryInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleQuerySubmit()}
                placeholder="Rechercher dans les résultats"
                className="w-full rounded-lg border border-neutral-200 bg-white pl-9 pr-3 py-2 text-sm text-neutral-800 shadow-inner focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              onClick={handleQuerySubmit}
              className="w-full sm:w-auto px-5 py-2.5 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition"
            >
              Mettre à jour
            </button>
          </div>
        </div>

        {loading && <div className="py-6 text-neutral-600">Chargement...</div>}
        {error && <div className="py-6 text-red-600">{error}</div>}

        {!loading && !error && (
          <>
            {results.length === 0 ? (
              <p className="text-neutral-500 py-6">Aucun résultat trouvé.</p>
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
