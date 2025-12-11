"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { useRouter, useSearchParams } from "next/navigation";
import { useSearch } from "@/src/context/SearchContext";
import { useAuth } from "@/src/context/AuthContext";
import AppHeader from "@/src/components/AppHeader";
import ListingCard from "@/src/components/ListingCard";
import ListingsGrid from "@/src/components/ListingsGrid";

export default function HomePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { setSearch, lastSearch } = useSearch();
  const { user, logout } = useAuth();

  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // ✅ Optimized initial query (prevents hydration mismatch & extra renders)
  const initialQuery = useMemo(() => {
    return searchParams.get("q") ?? lastSearch.query ?? "";
  }, [searchParams, lastSearch.query]);

  const [query, setQuery] = useState(initialQuery);

  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ✅ FIXED: Proper dependency handling (no more cascading renders)
  useEffect(() => {
    let isMounted = true;

    setLoading(true);
    setError(null);

    ApiService.fetchListings({ query: query || undefined })
      .then((data) => {
        if (isMounted) setListings(data);
      })
      .catch((e) => {
        if (isMounted) setError(e.message);
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [query]);

  // ✅ Safe outside-click handler
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setMenuOpen(false);
      }
    };

    if (menuOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
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
      {/* ✅ HEADER GLOBAL */}
      <AppHeader />

      {/* ✅ BANNER */}
      <section
        className="w-full h-[420px] bg-center bg-cover"
        style={{ backgroundImage: "url('/banner.jpg')", backgroundSize: "100%"  }}
      >
        <div className="w-full h-full bg-black/20"></div>
      </section>

      {/* ✅ LISTINGS */}
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

        <ListingsGrid
          listings={latest}
          columns={{ base: 2, sm: 3, md: 4, lg: 5 }}
          rows={{ base: 2, md: 2, lg: 2 }}
        />
      </section>
    </main>
  );
}
