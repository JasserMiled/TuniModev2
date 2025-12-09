"use client";

import { useEffect, useState } from "react";
import { ApiService } from "@/src/services/api";
import { FavoriteCollections } from "@/src/models/Favorite";
import { Protected } from "@/src/components/app/Protected";
import { useRouter } from "next/navigation";

export default function FavoritesPage() {
  const [collections, setCollections] = useState<FavoriteCollections | null>(null);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    ApiService.fetchFavorites()
      .then(setCollections)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <Protected>
      <div className="max-w-5xl mx-auto px-4 py-8 space-y-6">
        <h1 className="text-2xl font-semibold">Mes favoris</h1>
        {error && <p className="text-red-600">{error}</p>}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h2 className="text-lg font-semibold mb-3">Annonces</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {collections?.listings.map((listing) => (
                <div
                  key={listing.id}
                  className="border rounded-lg p-3 shadow-sm hover:shadow cursor-pointer"
                  onClick={() => router.push(`/listings/${listing.id}`)}
                >
                  <p className="text-sm text-neutral-500">{listing.city ?? "Tunisie"}</p>
                  <p className="font-semibold">{listing.title}</p>
                </div>
              ))}
            </div>
          </div>
          <div>
            <h2 className="text-lg font-semibold mb-3">Vendeurs</h2>
            <div className="space-y-3">
              {collections?.sellers.map((seller) => (
                <div
                  key={seller.id}
                  className="border rounded-lg p-3 flex items-center justify-between"
                  onClick={() => router.push(`/profile/${seller.id}`)}
                >
                  <div>
                    <p className="font-semibold">{seller.name}</p>
                    <p className="text-sm text-neutral-500">{seller.email}</p>
                  </div>
                  <button className="text-blue-600 text-sm">Voir profil</button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </Protected>
  );
}
