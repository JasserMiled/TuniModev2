"use client";

import { useEffect, useState } from "react";
import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { Protected } from "@/src/components/app/Protected";

export default function MyListingsPage() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    ApiService.fetchMyListings()
      .then(setListings)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <Protected>
      <div className="max-w-5xl mx-auto px-4 py-8 space-y-4">
        <h1 className="text-2xl font-semibold">Mes annonces</h1>
        {error && <p className="text-red-600">{error}</p>}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
          {listings.map((listing) => (
            <div key={listing.id} className="border rounded-lg p-3 shadow-sm">
              <p className="text-sm text-neutral-500">{listing.status ?? "publiée"}</p>
              <p className="font-semibold">{listing.title}</p>
              <p className="text-blue-600 font-semibold">{listing.price} DT</p>
            </div>
          ))}
        </div>
      </div>
    </Protected>
  );
}
