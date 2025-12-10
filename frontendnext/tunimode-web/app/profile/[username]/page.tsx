"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { User } from "@/src/models/User";
import { Listing } from "@/src/models/Listing";
import ListingsGrid from "@/src/components/ListingsGrid";
import AppHeader from "@/src/components/AppHeader";
import { useAuth } from "@/src/context/AuthContext";

type Review = {
  id: number;
  rating: number;
  comment?: string;
  createdAt: string;
  reviewerName?: string;
};

export default function ProfilePage() {
  const params = useParams<{ username: string }>();
  const userId = Number(params?.username);
  const router = useRouter();
  const { user: currentUser } = useAuth();

  const [user, setUser] = useState<User | null>(null);
  const [listings, setListings] = useState<Listing[]>([]);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [activeTab, setActiveTab] = useState<"annonces" | "avis">("annonces");
  const [error, setError] = useState<string | null>(null);

  const isCurrentUser = currentUser?.id === user?.id;

  useEffect(() => {
    if (!userId) return;

    ApiService.fetchUserProfile(userId)
      .then(setUser)
      .catch((e) => setError(e.message));

    ApiService.fetchUserListings(userId)
      .then(setListings)
      .catch(() => {});

    ApiService.fetchUserReviews(userId)
      .then(setReviews)
      .catch(() => {});
  }, [userId]);

  const averageRating =
    reviews.length > 0
      ? (
          reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
        ).toFixed(1)
      : null;

  return (
    <main className="bg-gray-50 min-h-screen">
      {/* ✅ HEADER GLOBAL */}
      <AppHeader />

      <div className="max-w-6xl mx-auto px-4 py-6 space-y-6">
        {error && <p className="text-red-600">{error}</p>}

        {/* ===================== */}
        {/* ✅ HEADER PROFIL */}
        {/* ===================== */}
        {user && (
          <div className="bg-white border rounded-xl p-5 flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-4">
              <div className="w-20 h-20 rounded-full bg-neutral-200 overflow-hidden flex items-center justify-center">
                {user.avatarUrl ? (
                  <img
                    src={user.avatarUrl}
                    className="w-full h-full object-cover"
                    alt="avatar"
                  />
                ) : (
                  <span className="text-3xl">👤</span>
                )}
              </div>

              <div>
                <h1 className="text-xl font-semibold">{user.name}</h1>

                {averageRating ? (
                  <p className="text-sm text-neutral-600">
                    ⭐ {averageRating} / 5 ({reviews.length} avis)
                  </p>
                ) : (
                  <p className="text-sm text-neutral-500">
                    Aucun avis pour le moment
                  </p>
                )}

                <p className="text-sm text-neutral-500 flex items-center gap-1">
                  📍 {user.address || "Adresse non renseignée"}
                </p>
              </div>
            </div>

            {isCurrentUser && (
              <button
                onClick={() => router.push("/account/settings")}
                className="px-4 py-2 border rounded-lg text-blue-600 hover:bg-blue-50"
              >
                Modifier profil
              </button>
            )}
          </div>
        )}

        {/* ===================== */}
        {/* ✅ TAB BAR */}
        {/* ===================== */}
        <div className="flex border-b">
          <button
            onClick={() => setActiveTab("annonces")}
            className={`px-6 py-2 font-semibold transition ${
              activeTab === "annonces"
                ? "border-b-2 border-blue-600 text-blue-600"
                : "text-gray-500"
            }`}
          >
            Annonces
          </button>

          <button
            onClick={() => setActiveTab("avis")}
            className={`px-6 py-2 font-semibold transition ${
              activeTab === "avis"
                ? "border-b-2 border-blue-600 text-blue-600"
                : "text-gray-500"
            }`}
          >
            Avis
          </button>
        </div>

        {/* ===================== */}
        {/* ✅ TAB ANNONCES */}
        {/* ===================== */}
        {activeTab === "annonces" && (
          <>
            {listings.length === 0 ? (
              <p className="text-neutral-500 py-6">
                Cet utilisateur n'a pas encore publié d'annonce.
              </p>
            ) : (
              <ListingsGrid
                listings={listings}
                columns={{ base: 2, sm: 3, md: 4, lg: 5 }}
                rows={{ base: 2, sm: 2, md: 2, lg: 2 }}
              />
            )}
          </>
        )}

        {/* ===================== */}
        {/* ✅ TAB AVIS */}
        {/* ===================== */}
        {activeTab === "avis" && (
          <div className="py-6 space-y-4">
            {reviews.length === 0 ? (
              <p className="text-neutral-500 text-center">
                Cet utilisateur n’a pas encore reçu d’avis.
              </p>
            ) : (
              reviews.map((review) => (
                <div
                  key={review.id}
                  className="bg-white border rounded-xl p-4 shadow-sm"
                >
                  <div className="flex items-center gap-2">
                    <span className="text-yellow-500 font-semibold">
                      ⭐ {review.rating}/5
                    </span>
                    <span className="text-neutral-500 text-sm">
                      {new Date(review.createdAt).toLocaleDateString()}
                    </span>
                  </div>

                  {review.comment && (
                    <p className="mt-2 text-neutral-800">{review.comment}</p>
                  )}

                  {review.reviewerName && (
                    <p className="mt-1 text-neutral-500 text-sm">
                      — {review.reviewerName}
                    </p>
                  )}
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </main>
  );
}
