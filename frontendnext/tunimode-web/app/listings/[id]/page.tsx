"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { useAuth } from "@/src/context/AuthContext";

export default function ListingDetailPage() {
  const params = useParams<{ id: string }>();
  const { user } = useAuth();
  const [listing, setListing] = useState<Listing | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const id = Number(params?.id);
    if (!id) return;
    ApiService.fetchListingDetail(id)
      .then(setListing)
      .catch((e) => setError(e.message));
  }, [params?.id]);

  if (error) return <div className="max-w-4xl mx-auto px-4 py-8 text-red-600">{error}</div>;
  if (!listing) return <div className="max-w-4xl mx-auto px-4 py-8">Chargement...</div>;

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 space-y-4">
      <div className="grid md:grid-cols-2 gap-4">
        <div className="rounded-xl overflow-hidden bg-neutral-100">
          <img src={listing.imageUrls?.[0] ?? "/placeholder.jpg"} alt={listing.title} className="w-full h-full object-cover" />
        </div>
        <div className="space-y-3">
          <h1 className="text-2xl font-semibold">{listing.title}</h1>
          <p className="text-blue-600 font-semibold text-xl">{listing.price} DT</p>
          <p className="text-neutral-600 whitespace-pre-line">{listing.description}</p>
          <div className="text-sm text-neutral-600 space-y-1">
            <p>Ville : {listing.city ?? "—"}</p>
            <p>Catégorie : {listing.categoryName ?? "—"}</p>
            <p>Vendeur : {listing.sellerName ?? "—"}</p>
            <p>Tailles : {listing.sizes?.join(", ") || "—"}</p>
          </div>
          <div className="flex gap-3">
            <button className="px-4 py-2 bg-blue-600 text-white rounded-lg">Commander</button>
            {user && <button className="px-4 py-2 border rounded-lg">Ajouter aux favoris</button>}
          </div>
        </div>
      </div>
    </div>
  );
}
