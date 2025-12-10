"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useSearch } from "@/src/context/SearchContext";
import { useAuth } from "@/src/context/AuthContext";
import SegmentedSearchButton from "./SegmentedSearchButton";
import QuickFiltersDialog, {
  QuickFiltersSelection,
} from "@/src/components/QuickFiltersDialog";
export default function AppHeader() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { setSearch, lastSearch } = useSearch();
  const { user, logout } = useAuth();

  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const [query, setQuery] = useState(
    searchParams.get("q") ?? lastSearch.query ?? ""
  );
    // ✅ ETATS POUR LA MODALE DE FILTRES
  const [filtersOpen, setFiltersOpen] = useState(false);

  const [lastFilters, setLastFilters] = useState<QuickFiltersSelection>({
    city: (lastSearch as any)?.city ?? null,
    minPrice: (lastSearch as any)?.minPrice ?? null,
    maxPrice: (lastSearch as any)?.maxPrice ?? null,
    categoryId: (lastSearch as any)?.categoryId ?? null,
    sizes: (lastSearch as any)?.sizes ?? [],
    colors: (lastSearch as any)?.colors ?? [],
    deliveryAvailable:
      (lastSearch as any)?.deliveryAvailable ?? null,
  });


  const handleSearch = () => {
    const trimmed = query.trim();
    if (!trimmed) return;

    const filters = { ...lastSearch, query: trimmed };
    setSearch(filters);
    router.push(`/search/results?query=${encodeURIComponent(trimmed)}`);
  };

const handleOpenFilters = () => {
  setFiltersOpen(true);
};

const handleApplyFilters = (selection: QuickFiltersSelection) => {
  const trimmed = query.trim();
  const filters = {
    ...lastSearch,
    query: trimmed,
    city: selection.city,
    minPrice: selection.minPrice,
    maxPrice: selection.maxPrice,
    categoryId: selection.categoryId,
    sizes: selection.sizes,
    colors: selection.colors,
    deliveryAvailable: selection.deliveryAvailable,
  };

  setLastFilters(selection);
  setSearch(filters);

  const targetUrl = trimmed
    ? `/search/results?query=${encodeURIComponent(trimmed)}`
    : "/search/results";

  router.push(targetUrl);
};

const handleResetFilters = () => {
  const trimmed = query.trim();
  const filters = { ...lastSearch, query: trimmed };

  const emptySelection: QuickFiltersSelection = {
    city: null,
    minPrice: null,
    maxPrice: null,
    categoryId: null,
    sizes: [],
    colors: [],
    deliveryAvailable: null,
  };

  setLastFilters(emptySelection);
  setSearch(filters);

  const targetUrl = trimmed
    ? `/search/results?query=${encodeURIComponent(trimmed)}`
    : "/search/results";

  router.push(targetUrl);
};

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setMenuOpen(false);
      }
    };

    if (menuOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }

    return () =>
      document.removeEventListener("mousedown", handleClickOutside);
  }, [menuOpen]);

  return (
  <header className="border-b border-neutral-200 bg-white">
    <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between gap-2">

      {/* ✅ GAUCHE — BURGER */}
      <div className="flex items-center flex-shrink-0">
        <button className="md:hidden p-2 border border-neutral-200 rounded-full">
          <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
          <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
          <span className="block w-5 h-0.5 bg-neutral-900" />
        </button>
      </div>

      {/* ✅ CENTRE — LOGO + SEARCH */}
      <div className="flex-1 min-w-0 flex items-center gap-3">

        {/* LOGO */}
        <Link
          href="/"
          className="text-lg font-semibold text-blue-600 whitespace-nowrap flex-shrink-0"
        >
          Tuni<span className="text-neutral-900">Mode</span>
        </Link>

        {/* SEARCH */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-3 bg-neutral-50 border border-neutral-200 rounded-full px-4 py-2 shadow-sm">
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSearch()}
              placeholder="Recherche..."
              className="flex-1 bg-transparent outline-none text-sm text-neutral-800 min-w-0"
            />
          </div>
        </div>

        {/* ✅ FILTRES DESKTOP SEULEMENT */}
        <div className="hidden md:block flex-shrink-0">
          <SegmentedSearchButton
            onSearch={handleSearch}
            onOpenFilters={handleOpenFilters}
          />
        </div>
      </div>

      {/* ✅ DROITE — USER / LOGIN */}
      <div className="flex items-center flex-shrink-0">
        {user ? (
          <div className="relative ml-2" ref={menuRef}>
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
                <Link
  href={`/profile/${user.id}`}
  className="block px-4 py-2 text-sm hover:bg-neutral-50"
>
  Mon profil
</Link>

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
            className="text-sm text-blue-600 font-semibold hover:underline ml-2"
          >
            Se connecter
          </Link>
        )}
      </div>

    </div>
	{filtersOpen && (
  <QuickFiltersDialog
    open={filtersOpen}
    onClose={() => setFiltersOpen(false)}
    initialSelection={lastFilters}
    onApply={handleApplyFilters}
    onReset={handleResetFilters}
  />
)}
  </header>
);

}
