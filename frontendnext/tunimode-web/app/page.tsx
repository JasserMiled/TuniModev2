"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { useRouter, useSearchParams } from "next/navigation";
import { useSearch } from "@/src/context/SearchContext";

export default function HomePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { setSearch, lastSearch } = useSearch();
  const [query, setQuery] = useState(searchParams.get("q") ?? lastSearch.query ?? "");
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    ApiService.fetchListings({ query: query || undefined })
      .then(setListings)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const latest = useMemo(() => listings.slice(0, 8), [listings]);

  const handleSearch = () => {
    const trimmed = query.trim();
    if (!trimmed) return;
    const filters = { ...lastSearch, query: trimmed };
    setSearch(filters);
    router.push(`/search/results?query=${encodeURIComponent(trimmed)}`);
  };

  const handleOpenFilters = () => {
    const trimmed = query.trim();
    const filters = { ...lastSearch, query: trimmed };
    setSearch(filters);

    const targetUrl = trimmed
      ? `/search/results?query=${encodeURIComponent(trimmed)}`
      : "/search/results";

    router.push(targetUrl);
  };

  return (
    <main className="bg-white min-h-screen">
      <div className="border-b border-neutral-200 bg-white">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center gap-4">
          <button
            aria-label="Ouvrir le menu"
            className="p-2 border border-neutral-200 rounded-full hover:bg-neutral-50"
          >
            <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
            <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
            <span className="block w-5 h-0.5 bg-neutral-900" />
          </button>

          <Link href="/" className="text-2xl font-semibold text-blue-600 whitespace-nowrap">
            Tuni<span className="text-neutral-900">Mode</span>
          </Link>

          <div className="flex-1">
            <div className="flex items-center gap-3 bg-neutral-50 border border-neutral-200 rounded-full px-4 py-2 shadow-sm">
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSearch()}
                placeholder="Recherche..."
                className="flex-1 bg-transparent outline-none text-sm text-neutral-800"
              />
            </div>
          </div>

          <button
            onClick={handleSearch}
            className="px-4 py-2 rounded-full border border-neutral-200 text-sm font-medium hover:bg-neutral-50 whitespace-nowrap"
          >
            Chercher
          </button>

          <button
            onClick={handleOpenFilters}
            className="px-5 py-2 bg-blue-600 text-white rounded-full text-sm font-semibold shadow-sm hover:bg-blue-700 whitespace-nowrap"
          >
            Filtrer
          </button>

          <Link
            href="/auth/login"
            className="text-sm text-blue-600 font-semibold whitespace-nowrap hover:underline"
          >
            Se connecter
          </Link>
        </div>
      </div>

      <header className="max-w-6xl mx-auto px-4 py-10 flex flex-col md:flex-row md:items-center gap-6">
        <div className="flex-1 space-y-3">
          <p className="text-sm text-blue-600 font-medium">Plateforme n°1 de mode circulaire en Tunisie</p>
          <h1 className="text-3xl font-semibold text-neutral-900 leading-snug">
            Découvre les dernières trouvailles sélectionnées pour toi
          </h1>
          <p className="text-neutral-600 max-w-2xl">
            Retrouve les mêmes parcours que dans l'application Flutter : recherche, filtres, et navigation vers les fiches annonces.
          </p>
          <div className="flex flex-col md:flex-row gap-3">
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Rechercher des articles"
              className="flex-1 border border-neutral-200 rounded-xl px-4 py-3 shadow-sm"
            />
            <button
              onClick={handleSearch}
              className="bg-blue-600 text-white px-5 py-3 rounded-xl font-semibold"
            >
              Chercher
            </button>
          </div>
          <div className="flex gap-3 text-sm text-neutral-600">
            <Link href="/auth/login" className="underline">Connexion</Link>
            <Link href="/auth/register" className="underline">Créer un compte</Link>
            <Link href="/dashboard" className="underline">Tableau de bord</Link>
          </div>
        </div>
        <div className="w-full md:w-[420px]">
          <div className="relative overflow-hidden rounded-3xl shadow-xl bg-gradient-to-r from-blue-600 via-indigo-500 to-violet-500 text-white px-8 py-10">
            <div className="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_20%_20%,white,transparent_30%),radial-gradient(circle_at_80%_0%,white,transparent_25%)]" />
            <div className="relative space-y-3">
              <p className="text-xs uppercase tracking-[0.25em] text-white/70">Expérience premium</p>
              <h2 className="text-2xl font-semibold leading-snug">Commandes sécurisées et suivies</h2>
              <p className="text-white/85 text-sm leading-relaxed">
                Profite d&apos;un retrait ou d&apos;une livraison fiable selon les annonces, avec des vendeurs vérifiés et un suivi
                en temps réel.
              </p>
              <div className="flex items-center gap-3 text-sm">
                <span className="px-3 py-1 rounded-full bg-white/15 border border-white/20">Vendeurs vérifiés</span>
                <span className="px-3 py-1 rounded-full bg-white/15 border border-white/20">Paiements sécurisés</span>
              </div>
              <button className="mt-2 inline-flex items-center gap-2 px-5 py-3 bg-white text-blue-700 rounded-full font-semibold shadow-md hover:shadow-lg transition">
                Découvrir les annonces
                <span aria-hidden>→</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      <section className="max-w-6xl mx-auto px-4 pb-12">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold">Dernières annonces</h2>
          <Link href="/search/results" className="text-blue-600 underline text-sm">Voir tout</Link>
        </div>
        {loading && <div className="py-6 text-neutral-600">Chargement...</div>}
        {error && <div className="py-6 text-red-600">{error}</div>}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {latest.map((listing) => (
            <article
              key={listing.id}
              className="border border-neutral-200 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition cursor-pointer"
              onClick={() => router.push(`/listings/${listing.id}`)}
            >
              <div className="aspect-[4/3] bg-neutral-100">
                <img
                  src={listing.imageUrls?.[0] ?? "/placeholder-listing.svg"}
                  alt={listing.title}
                  className="w-full h-full object-cover"
                />

              </div>
              <div className="p-3 space-y-1">
                <p className="text-sm text-neutral-500">{listing.city || "Tunisie"}</p>
                <h3 className="font-semibold text-neutral-900 line-clamp-2">{listing.title}</h3>
                <p className="text-blue-600 font-semibold">{listing.price} DT</p>
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
