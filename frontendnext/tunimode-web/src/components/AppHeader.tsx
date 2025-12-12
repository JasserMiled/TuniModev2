"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { SearchFilters, useSearch } from "@/src/context/SearchContext";
import { useAuth } from "@/src/context/AuthContext";
import SegmentedSearchButton from "./SegmentedSearchButton";
import QuickFiltersDialog, {
  QuickFiltersSelection,
} from "@/src/components/QuickFiltersDialog";
import { buildResultsUrl } from "@/src/utils/searchFilters";
import NewListingModal from "./NewListingModal";

export default function AppHeader() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { setSearch, lastSearch } = useSearch();
  const { user, logout } = useAuth();

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [listingModalOpen, setListingModalOpen] = useState(false);
  const drawerRef = useRef<HTMLDivElement>(null);

  const [query, setQuery] = useState(
    searchParams.get("q") ?? lastSearch.query ?? ""
  );

  const [filtersOpen, setFiltersOpen] = useState(false);

  const normalizeSelection = (): QuickFiltersSelection => ({
    city: lastSearch.city ?? null,
    minPrice: lastSearch.minPrice ?? null,
    maxPrice: lastSearch.maxPrice ?? null,
    categoryId: lastSearch.categoryId ?? null,
    sizes: lastSearch.sizes ?? [],
    colors: lastSearch.colors ?? [],
    deliveryAvailable: lastSearch.deliveryAvailable ?? null,
  });

  const normalizedSelection = useMemo(normalizeSelection, [lastSearch]);

  const [lastFilters, setLastFilters] = useState<QuickFiltersSelection>(
    normalizedSelection
  );

  const areSelectionsEqual = (
    a: QuickFiltersSelection,
    b: QuickFiltersSelection
  ) => {
    return (
      a.city === b.city &&
      a.minPrice === b.minPrice &&
      a.maxPrice === b.maxPrice &&
      a.categoryId === b.categoryId &&
      a.deliveryAvailable === b.deliveryAvailable &&
      a.sizes.join(",") === b.sizes.join(",") &&
      a.colors.join(",") === b.colors.join(",")
    );
  };

  useEffect(() => {
    setLastFilters((prev) =>
      areSelectionsEqual(prev, normalizedSelection) ? prev : normalizedSelection
    );
  }, [normalizedSelection]);

  useEffect(() => {
    const nextQuery =
      searchParams.get("query") ?? searchParams.get("q") ?? "";

    setQuery((prev) => (prev === nextQuery ? prev : nextQuery));
  }, [searchParams]);

  const handleSearch = () => {
    const trimmed = query.trim();
    if (!trimmed) return;

    const filters: SearchFilters = { ...lastSearch, query: trimmed };
    const nextUrl = buildResultsUrl(filters);

    // Avoid spamming the search endpoint with identical queries.
    if (lastSearch.query === trimmed && buildResultsUrl(lastSearch) === nextUrl) {
      return;
    }

    setSearch(filters);
    router.push(nextUrl);
  };

  const handleOpenFilters = () => {
    setFiltersOpen(true);
  };

  const handleApplyFilters = (selection: QuickFiltersSelection) => {
    const trimmed = query.trim();
    const filters: SearchFilters = {
      ...lastSearch,
      query: trimmed,
      city: selection.city ?? undefined,
      minPrice: selection.minPrice ?? undefined,
      maxPrice: selection.maxPrice ?? undefined,
      categoryId: selection.categoryId ?? undefined,
      sizes: selection.sizes,
      colors: selection.colors,
      deliveryAvailable: selection.deliveryAvailable ?? undefined,
    };

    setLastFilters(selection);
    setSearch(filters);

    router.push(buildResultsUrl(filters));
  };

  const handleResetFilters = () => {
    const trimmed = query.trim();
    const filters: SearchFilters = { ...lastSearch, query: trimmed };

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

    router.push(buildResultsUrl(filters));
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (drawerRef.current && !drawerRef.current.contains(event.target as Node)) {
        setDrawerOpen(false);
      }
    };

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setDrawerOpen(false);
      }
    };

    if (drawerOpen) {
      document.addEventListener("mousedown", handleClickOutside);
      document.addEventListener("keydown", handleEscape);
    }

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleEscape);
    };
  }, [drawerOpen]);
  const canCreateListing = useMemo(() => {
    if (!user?.role) return false;
    const normalizedRole = user.role.toLowerCase();
    return normalizedRole === "seller";
  }, [user?.role]);

  const canManageListings = canCreateListing;

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
        <div className="flex items-center gap-3 flex-shrink-0">
          {canCreateListing && (
            <button
              onClick={() => setListingModalOpen(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-full text-sm font-semibold hover:bg-blue-700 transition"
            >
              Ajouter une annonce
            </button>
          )}

          <button
            onClick={() => setDrawerOpen(true)}
            className="p-2 border border-neutral-200 rounded-full hover:bg-neutral-50"
            aria-label="Ouvrir le menu"
          >
            <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
            <span className="block w-5 h-0.5 bg-neutral-900 mb-1" />
            <span className="block w-5 h-0.5 bg-neutral-900" />
          </button>
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
      <NewListingModal
        open={listingModalOpen}
        onClose={() => setListingModalOpen(false)}
      />

      {drawerOpen && (
        <div className="fixed inset-0 z-30">
          <div
            className="absolute inset-0 bg-black/30"
            onClick={() => setDrawerOpen(false)}
          />

          <div
            ref={drawerRef}
            className="absolute right-0 top-0 h-full w-72 max-w-full bg-white shadow-2xl border-l border-neutral-200 flex flex-col"
          >
            <div className="flex items-center justify-between px-4 py-3 border-b border-neutral-200">
              <p className="text-lg font-semibold">Menu</p>
              <button
                onClick={() => setDrawerOpen(false)}
                className="p-2 rounded-full hover:bg-neutral-100"
                aria-label="Fermer le menu"
              >
                ✕
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-4 py-4 space-y-2">
              <Link
                href="/"
                onClick={() => setDrawerOpen(false)}
                className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
              >
                Accueil
              </Link>

              <Link
                href="/search/results"
                onClick={() => setDrawerOpen(false)}
                className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
              >
                Découvrir
              </Link>

              {user ? (
                <>
                  <Link
                    href={`/profile/${user.id}`}
                    onClick={() => setDrawerOpen(false)}
                    className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
                  >
                    Mon profil
                  </Link>

                  <Link
                    href="/favorites"
                    onClick={() => setDrawerOpen(false)}
                    className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
                  >
                    Mes favoris
                  </Link>

                  {canManageListings && (
                    <Link
                      href="/dashboard/listings"
                      onClick={() => setDrawerOpen(false)}
                      className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
                    >
                      Mes annonces
                    </Link>
                  )}

                  <Link
                    href="/orders"
                    onClick={() => setDrawerOpen(false)}
                    className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
                  >
                    Mes commandes
                  </Link>

                  <Link
                    href="/account/settings"
                    onClick={() => setDrawerOpen(false)}
                    className="block px-3 py-2 rounded-lg hover:bg-neutral-100"
                  >
                    Paramètres
                  </Link>

                  <button
                    onClick={() => {
                      logout();
                      setDrawerOpen(false);
                    }}
                    className="w-full text-left px-3 py-2 rounded-lg hover:bg-neutral-100 text-red-600"
                  >
                    Se déconnecter
                  </button>
                </>
              ) : (
                <Link
                  href="/auth/login"
                  onClick={() => setDrawerOpen(false)}
                  className="block px-3 py-2 rounded-lg hover:bg-neutral-100 text-blue-600 font-semibold"
                >
                  Se connecter
                </Link>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
