"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { useRouter, useSearchParams } from "next/navigation";
import { useSearch } from "@/src/context/SearchContext";
import { useAuth } from "@/src/context/AuthContext";

export default function HomePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { setSearch, lastSearch } = useSearch();
  const { user, logout } = useAuth();

  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const [query, setQuery] = useState(
    searchParams.get("q") ?? lastSearch.query ?? ""
  );

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

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setMenuOpen(false);
      }
    };

    if (menuOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }

    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [menuOpen]);

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
      {/* HEADER */}
{/* ✅ HEADER COMPLET */}
<div className="border-b border-neutral-200 bg-white relative">

  {/* ✅ HAMBURGER GAUCHE — COLLÉ AU BORD */}
  <button
    aria-label="Ouvrir le menu"
    className="absolute left-4 top-1/2 -translate-y-1/2 p-2 border border-neutral-200 rounded-full hover:bg-neutral-50 z-30"
  >
    <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
    <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
    <span className="block w-5 h-0.5 bg-neutral-900" />
  </button>

  {/* ✅ HAMBURGER DROIT / LOGIN — COLLÉ AU BORD */}
  {user ? (
    <div
      className="absolute right-4 top-1/2 -translate-y-1/2 z-30"
      ref={menuRef}
    >
      <button
        onClick={() => setMenuOpen((open) => !open)}
        className="p-2 border border-neutral-200 rounded-full hover:bg-neutral-50"
      >
        <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
        <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
        <span className="block w-5 h-0.5 bg-neutral-900" />
      </button>

      {menuOpen && (
        <div className="absolute right-0 top-12 w-56 rounded-2xl border border-neutral-200 bg-white shadow-lg py-2 z-20">
          <Link href="/profile" className="block px-4 py-2 text-sm hover:bg-neutral-50">Mon profil</Link>
          <Link href="/favorites" className="block px-4 py-2 text-sm hover:bg-neutral-50">Mes favoris</Link>
          <Link href="/dashboard/listings" className="block px-4 py-2 text-sm hover:bg-neutral-50">Mes annonces</Link>
          <Link href="/orders" className="block px-4 py-2 text-sm hover:bg-neutral-50">Mes commandes</Link>
          <Link href="/account/settings" className="block px-4 py-2 text-sm hover:bg-neutral-50">Paramètres</Link>

          <button
            onClick={() => {
              logout();
              setMenuOpen(false);
            }}
            className="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-neutral-50"
          >
            Se déconnecter
          </button>
        </div>
      )}
    </div>
  ) : (
    <Link
      href="/auth/login"
      className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-blue-600 font-semibold hover:underline z-30"
    >
      Se connecter
    </Link>
  )}

  {/* ✅ CONTENU CENTRÉ */}
  <div className="max-w-6xl mx-auto px-4 py-4 flex items-center gap-4">

    {/* LOGO */}
    <Link
      href="/"
      className="text-2xl font-semibold text-blue-600 whitespace-nowrap"
    >
      Tuni<span className="text-neutral-900">Mode</span>
    </Link>

    {/* SEARCH */}
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

    {/* BOUTONS CENTRÉS À DROITE DU SEARCH */}
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
  </div>
</div>
      

      {/* BANNER */}
      <section
        className="w-full h-[420px] bg-center bg-cover"
        style={{ backgroundImage: "url('/banner.jpg')" }}
      >
        <div className="w-full h-full bg-black/20"></div>
      </section>

      {/* LISTINGS */}
      <section className="max-w-6xl mx-auto px-4 pt-16 pb-12">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-neutral-900">
            Derniers articles mis en ligne
          </h2>
          <p className="text-sm text-neutral-600 mt-1">
            Choisis tes prochaines trouvailles parmi des milliers de vêtements et accessoires.
          </p>
        </div>

        {loading && <div className="py-6 text-neutral-600">Chargement...</div>}
        {error && <div className="py-6 text-red-600">{error}</div>}

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {latest.map((listing) => (
            <article
              key={listing.id}
              className="border border-neutral-200 rounded-md overflow-hidden shadow-sm hover:shadow-md transition cursor-pointer flex flex-col"
              onClick={() => router.push(`/listings/${listing.id}`)}
            >
              <div className="h-56 bg-neutral-100">
                <img
                  src={listing.imageUrls?.[0] ?? "/placeholder-listing.svg"}
                  alt={listing.title}
                  className="w-full h-full object-cover"
                />
              </div>

              <div className="p-3 space-y-0.5">
                <p className="text-sm text-neutral-500">
                  {listing.city || "Tunisie"}
                </p>
                <h3 className="font-semibold text-neutral-900 line-clamp-2">
                  {listing.title}
                </h3>
                <p className="text-blue-600 font-semibold">
                  {listing.price} DT
                </p>
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
