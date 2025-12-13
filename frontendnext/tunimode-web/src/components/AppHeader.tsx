"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";

import { useAuth } from "@/src/context/AuthContext";
import { useSearch, SearchFilters } from "@/src/context/SearchContext";

import SegmentedSearchButton from "./SegmentedSearchButton";
import QuickFiltersDialog, {
  QuickFiltersSelection,
} from "@/src/components/QuickFiltersDialog";
import NewListingModal from "./NewListingModal";
import Drawer from "@/src/components/Drawer";

import { buildResultsUrl } from "@/src/utils/searchFilters";

import {
  MdHome,
  MdInfo,
  MdDescription,
  MdContactMail,
} from "react-icons/md";
import { ArrowRightOnRectangleIcon } from "@heroicons/react/24/solid";

/* ---------------- HAMBURGER ICON ---------------- */
function HamburgerIcon() {
  return (
    <div className="flex flex-col items-center gap-1.5">
      <span className="block w-6 h-[2.5px] bg-neutral-900 rounded-full" />
      <span className="block w-6 h-[2.5px] bg-neutral-900 rounded-full" />
      <span className="block w-6 h-[2.5px] bg-neutral-900 rounded-full" />
    </div>
  );
}

/* ---------------- APP HEADER ---------------- */
export default function AppHeader() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const { user, logout } = useAuth();
  const { setSearch, lastSearch } = useSearch();

  /* ---------------- DRAWERS ---------------- */
  const [navDrawerOpen, setNavDrawerOpen] = useState(false);
  const [userDrawerOpen, setUserDrawerOpen] = useState(false);

  /* ---------------- SEARCH ---------------- */
  const [query, setQuery] = useState(
    searchParams.get("q") ?? lastSearch.query ?? ""
  );

  const [filtersOpen, setFiltersOpen] = useState(false);
  const [listingModalOpen, setListingModalOpen] = useState(false);

  /* ---------------- URL ↔ QUERY SYNC ---------------- */
  useEffect(() => {
    const nextQuery =
      searchParams.get("query") ?? searchParams.get("q") ?? "";

    setQuery((prev) => (prev === nextQuery ? prev : nextQuery));
  }, [searchParams]);

  /* ---------------- SELLER ROLE ---------------- */
  const canCreateListing =
    user?.role?.toLowerCase() === "seller";

  /* ---------------- FILTER NORMALIZATION ---------------- */
  const normalizeSelection = (): QuickFiltersSelection => ({
    city: lastSearch.city ?? null,
    minPrice: lastSearch.minPrice ?? null,
    maxPrice: lastSearch.maxPrice ?? null,
    categoryId: lastSearch.categoryId ?? null,
    sizes: lastSearch.sizes ?? [],
    colors: lastSearch.colors ?? [],
    deliveryAvailable: lastSearch.deliveryAvailable ?? null,
  });

  const normalizedSelection = useMemo(
    normalizeSelection,
    [lastSearch]
  );

  const [lastFilters, setLastFilters] =
    useState<QuickFiltersSelection>(normalizedSelection);

  const areSelectionsEqual = (
    a: QuickFiltersSelection,
    b: QuickFiltersSelection
  ) =>
    a.city === b.city &&
    a.minPrice === b.minPrice &&
    a.maxPrice === b.maxPrice &&
    a.categoryId === b.categoryId &&
    a.deliveryAvailable === b.deliveryAvailable &&
    a.sizes.join(",") === b.sizes.join(",") &&
    a.colors.join(",") === b.colors.join(",");

  useEffect(() => {
    setLastFilters((prev) =>
      areSelectionsEqual(prev, normalizedSelection)
        ? prev
        : normalizedSelection
    );
  }, [normalizedSelection]);

  /* ---------------- SEARCH HANDLER ---------------- */
  const handleSearch = () => {
    const trimmed = query.trim();
    if (!trimmed) return;

    const filters: SearchFilters = {
      ...lastSearch,
      query: trimmed,
    };

    const nextUrl = buildResultsUrl(filters);

    if (
      lastSearch.query === trimmed &&
      buildResultsUrl(lastSearch) === nextUrl
    ) {
      return;
    }

    setSearch(filters);
    router.push(nextUrl);
  };

  /* ---------------- FILTER HANDLERS ---------------- */
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

    const filters: SearchFilters = {
      ...lastSearch,
      query: trimmed,
    };

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

  /* ---------------- DRAWER LINKS ---------------- */
  const drawerLinks = [
    { href: "/", label: "Accueil", Icon: MdHome },
    { href: "/about", label: "À propos", Icon: MdInfo },
    { href: "/terms", label: "Conditions d'utilisation", Icon: MdDescription },
    { href: "/contact", label: "Contact", Icon: MdContactMail },
  ];

  /* ================= RENDER ================= */
  return (
    <>
      {/* ================= HEADER ================= */}
      <header className="relative z-50 border-b border-neutral-200 bg-white">
        {/* LEFT BURGER */}
        <button
          onClick={() => setNavDrawerOpen(true)}
          className="absolute left-6 top-1/2 -translate-y-1/2 p-3 hover:opacity-70 transition"
          aria-label="Menu"
        >
          <HamburgerIcon />
        </button>

        {/* RIGHT BURGER (USER) */}
        {user && (
          <button
            onClick={() => setUserDrawerOpen(true)}
            className="absolute right-6 top-1/2 -translate-y-1/2 p-3 hover:opacity-70 transition"
            aria-label="Menu utilisateur"
          >
            <HamburgerIcon />
          </button>
        )}

        <div className="max-w-6xl mx-auto px-4 py-2 flex items-center justify-center gap-3">
          {/* LOGO */}
          <Link href="/" className="flex items-center">
            <img
              src="/tunimode_logo.svg"
              alt="TuniMode"
              className="h-6 w-auto"
            />
          </Link>

          {/* SEARCH */}
          <div className="flex-1 max-w-md">
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSearch()}
              placeholder="Recherche…"
              className="w-full rounded-md border border-neutral-200 px-4 py-2 text-sm outline-none"
            />
          </div>

          {/* SEARCH + FILTERS (DESKTOP) */}
          <div className="hidden md:block">
            <SegmentedSearchButton
              onSearch={handleSearch}
              onOpenFilters={() => setFiltersOpen(true)}
            />
          </div>

          {/* ADD LISTING (SELLER ONLY – DESKTOP) */}
          {canCreateListing && (
            <button
              onClick={() => setListingModalOpen(true)}
              className="hidden md:inline-flex ml-2 px-4 py-2 rounded-full bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 transition"
            >
              Ajouter une annonce
            </button>
          )}
        </div>

        {/* LOGIN (NOT CONNECTED) */}
        {!user && (
          <Link
            href="/auth/login"
            className="absolute right-16 top-1/2 -translate-y-1/2 flex items-center gap-1 text-sm font-semibold text-blue-900 hover:text-blue-800 transition"
          >
            <ArrowRightOnRectangleIcon className="w-6 h-5" />
            Se connecter
          </Link>
        )}
      </header>

      {/* ================= NAV DRAWER ================= */}
      <Drawer
        open={navDrawerOpen}
        onClose={() => setNavDrawerOpen(false)}
        side="left"
        title="Menu"
      >
        <nav className="py-4">
          <ul className="space-y-1">
            {drawerLinks.map(({ href, label, Icon }) => (
              <li key={href}>
                <Link
                  href={href}
                  onClick={() => setNavDrawerOpen(false)}
                  className="flex items-center gap-3 px-4 py-3 hover:bg-neutral-100"
                >
                  <Icon className="text-xl text-neutral-600" />
                  {label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      </Drawer>

      {/* ================= USER DRAWER ================= */}
      {user && (
        <Drawer
          open={userDrawerOpen}
          onClose={() => setUserDrawerOpen(false)}
          side="right"
          title="Mon compte"
        >
          <nav className="py-4">
            <ul className="space-y-1">
              <li>
                <Link
                  href={`/profile/${user.id}`}
                  onClick={() => setUserDrawerOpen(false)}
                  className="block px-4 py-3 hover:bg-neutral-100"
                >
                  Mon profil
                </Link>
              </li>

              <li>
                <Link
                  href="/favorites"
                  onClick={() => setUserDrawerOpen(false)}
                  className="block px-4 py-3 hover:bg-neutral-100"
                >
                  Mes favoris
                </Link>
              </li>

              {canCreateListing && (
                <li>
                  <Link
                    href="/dashboard/listings"
                    onClick={() => setUserDrawerOpen(false)}
                    className="block px-4 py-3 hover:bg-neutral-100"
                  >
                    Mes annonces
                  </Link>
                </li>
              )}

              <li>
                <Link
                  href="/orders"
                  onClick={() => setUserDrawerOpen(false)}
                  className="block px-4 py-3 hover:bg-neutral-100"
                >
                  Mes commandes
                </Link>
              </li>

              <li>
                <Link
                  href="/account/settings"
                  onClick={() => setUserDrawerOpen(false)}
                  className="block px-4 py-3 hover:bg-neutral-100"
                >
                  Paramètres
                </Link>
              </li>

              <li className="border-t mt-2 pt-2">
                <button
                  onClick={() => {
                    logout();
                    setUserDrawerOpen(false);
                  }}
                  className="w-full text-left px-4 py-3 text-red-600 hover:bg-neutral-100"
                >
                  Se déconnecter
                </button>
              </li>
            </ul>
          </nav>
        </Drawer>
      )}

      {/* ================= MODALS ================= */}
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
    </>
  );
}
