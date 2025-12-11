"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { ApiService } from "@/src/services/api";
import { FavoriteCollections } from "@/src/models/Favorite";
import { Protected } from "@/src/components/app/Protected";
import AppHeader from "@/src/components/AppHeader";
import ListingsGrid from "@/src/components/ListingsGrid";
import TabMenu from "@/src/components/TabMenu";

import { FaHeart } from "react-icons/fa";

export default function FavoritesPage() {
  const [collections, setCollections] =
    useState<FavoriteCollections | null>(null);

  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] =
    useState<"listings" | "sellers">("listings");

  const router = useRouter();

  // LOAD FAVORITES
  const loadFavorites = async () => {
    try {
      const data = await ApiService.fetchFavorites();

      setCollections({
        ...data,
        listings: data.listings,
        sellers: data.sellers,
      });
    } catch (e: any) {
      setError(e.message);
    }
  };


  useEffect(() => {
    loadFavorites();
  }, []);

  // REMOVE LISTING
  const removeListing = async (id: number) => {
    await ApiService.removeFavoriteListing(id);
    loadFavorites();
  };

  // REMOVE SELLER
  const removeSeller = async (id: number) => {
    await ApiService.removeFavoriteSeller(id);
    loadFavorites();
  };

  return (
    <Protected>
      <main className="bg-gray-50 min-h-screen">
        <AppHeader />

        <div className="max-w-6xl mx-auto px-4 py-8">
          <h1 className="text-2xl font-semibold mb-6">Mes favoris</h1>

          {error && <p className="text-red-600 mb-4">{error}</p>}

          <TabMenu
            className="mb-6"
            activeKey={activeTab}
            onChange={setActiveTab}
            tabs={[
              { key: "listings", label: "Annonces" },
              { key: "sellers", label: "Vendeurs" },
            ]}
          />

          {/* LISTINGS (annonces favorites) */}
          {activeTab === "listings" && collections && (
            <>
              {collections.listings.length === 0 ? (
                <p className="text-neutral-500 py-6">
                  Aucune annonce dans vos favoris.
                </p>
              ) : (
                <ListingsGrid
                  listings={collections.listings}
                  columns={{ base: 2, sm: 3, md: 4, lg: 5 }}
                  rows={{ base: 2, sm: 2, md: 2, lg: 2 }}
                  renderOverlay={(listing) => (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        removeListing(listing.id);
                      }}
                      className="hover:scale-125 transition"
                      title="Retirer des favoris"
                    >
                      <FaHeart className="text-red-600 drop-shadow" size={18} />
                    </button>
                  )}
                />
              )}
            </>
          )}

          {/* SELLERS (vendeurs favoris) */}
          {activeTab === "sellers" && collections && (
            <>
              {collections.sellers.length === 0 ? (
                <p className="text-neutral-500 py-6">
                  Aucun vendeur enregistré en favori.
                </p>
              ) : (
                <div className="space-y-4">
                  {collections.sellers.map((seller) => (
                    <div
                      key={seller.id}
                      className="bg-white border border-neutral-200 rounded-md p-4 shadow-sm hover:shadow transition flex items-center justify-between"
                    >
                      <div
                        className="cursor-pointer"
                        onClick={() => router.push(`/profile/${seller.id}`)}
                      >
                        <p className="font-semibold">{seller.name}</p>
                        <p className="text-sm text-neutral-500">
                          {seller.email}
                        </p>
                      </div>

                      <button
                        onClick={() => removeSeller(seller.id)}
                        className="text-red-600 hover:scale-110 transition"
                        title="Retirer ce vendeur"
                      >
                        <FaHeart size={20} />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </main>
    </Protected>
  );
}
