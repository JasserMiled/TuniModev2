"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { Protected } from "@/src/components/app/Protected";
import AppHeader from "@/src/components/AppHeader";
import ListingsGrid from "@/src/components/ListingsGrid";

export default function MyListingsPage() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] =
    useState<"online" | "deleted">("online");

  const router = useRouter();

  // ✅ LOAD MY LISTINGS
  const loadMyListings = async () => {
    try {
      const data = await ApiService.fetchMyListings();
      setListings(data);
    } catch (e: any) {
      setError(e.message);
    }
  };

  useEffect(() => {
    loadMyListings();
  }, []);

  const onlineListings = listings.filter(
    (listing) => !listing.isDeleted
  );

  const deletedListings = listings.filter(
    (listing) => listing.isDeleted
  );

  return (
    <Protected>
      <main className="bg-gray-50 min-h-screen">
        <AppHeader />

        <div className="max-w-6xl mx-auto px-4 py-8">
          {/* ✅ TITLE */}
          <h1 className="text-2xl font-semibold mb-6">
            Mes annonces
          </h1>

          {error && (
            <p className="text-red-600 mb-4">
              {error}
            </p>
          )}

          {/* ✅ TAB BAR (EN LIGNE / SUPPRIMÉE) */}
          <div className="flex border-b mb-6">
            <button
              onClick={() => setActiveTab("online")}
              className={`px-6 py-2 font-semibold transition ${
                activeTab === "online"
                  ? "border-b-2 border-blue-600 text-blue-600"
                  : "text-gray-500"
              }`}
            >
              En ligne
            </button>

            <button
              onClick={() => setActiveTab("deleted")}
              className={`px-6 py-2 font-semibold transition ${
                activeTab === "deleted"
                  ? "border-b-2 border-blue-600 text-blue-600"
                  : "text-gray-500"
              }`}
            >
              Supprimée
            </button>
          </div>

          {/* ========================= */}
          {/* ✅ TAB EN LIGNE */}
          {/* ========================= */}
          {activeTab === "online" && (
            <>
              {onlineListings.length === 0 ? (
                <p className="text-neutral-500 py-6">
                  Aucune annonce en ligne pour le moment.
                </p>
              ) : (
                <ListingsGrid
                  listings={onlineListings}
                  columns={{ base: 2, sm: 3, md: 4, lg: 5 }}
                  rows={{ base: 2, sm: 2, md: 2, lg: 2 }}
                />
              )}
            </>
          )}

          {/* ========================= */}
          {/* ✅ TAB SUPPRIMÉE */}
          {/* ========================= */}
          {activeTab === "deleted" && (
            <>
              {deletedListings.length === 0 ? (
                <p className="text-neutral-500 py-6">
                  Aucune annonce supprimée.
                </p>
              ) : (
                <ListingsGrid
                  listings={deletedListings}
                  columns={{ base: 2, sm: 3, md: 4, lg: 5 }}
                  rows={{ base: 2, sm: 2, md: 2, lg: 2 }}
                />
              )}
            </>
          )}
        </div>
      </main>
    </Protected>
  );
}
