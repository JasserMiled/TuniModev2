"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { User } from "@/src/models/User";
import { Listing } from "@/src/models/Listing";

export default function ProfilePage() {
  const params = useParams<{ username: string }>();
  const userId = Number(params?.username);
  const [user, setUser] = useState<User | null>(null);
  const [listings, setListings] = useState<Listing[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!userId) return;
    ApiService.fetchUserProfile(userId)
      .then(setUser)
      .catch((e) => setError(e.message));
    ApiService.fetchUserListings(userId)
      .then(setListings)
      .catch(() => {});
  }, [userId]);

  return (
    <div className="max-w-5xl mx-auto px-4 py-8 space-y-4">
      {error && <p className="text-red-600">{error}</p>}
      {user ? (
        <div className="space-y-2">
          <h1 className="text-2xl font-semibold">{user.name}</h1>
          <p className="text-neutral-600">{user.email}</p>
          <p className="text-neutral-600">{user.address}</p>
        </div>
      ) : (
        <p>Chargement...</p>
      )}

      <div className="space-y-3">
        <h2 className="text-lg font-semibold">Annonces</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
          {listings.map((listing) => (
            <div key={listing.id} className="border rounded-lg p-3 shadow-sm">
              <p className="text-sm text-neutral-500">{listing.city ?? "Tunisie"}</p>
              <p className="font-semibold">{listing.title}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
