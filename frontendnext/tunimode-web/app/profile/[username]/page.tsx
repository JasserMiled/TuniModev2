"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { User } from "@/src/models/User";
import { Listing } from "@/src/models/Listing";
import ListingsGrid from "@/src/components/ListingsGrid";
import AppHeader from "@/src/components/AppHeader";
import { useAuth } from "@/src/context/AuthContext";
import VendorCard from "@/src/components/VendorCard";
import TabMenu from "@/src/components/TabMenu";


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
  const [avatarError, setAvatarError] = useState(false);

  const isCurrentUser = currentUser?.id === user?.id;
  const isClient = user?.role === "client";

  useEffect(() => {
    if (!userId) return;

    ApiService.fetchUserProfile(userId)
      .then((profile) =>
        setUser({
          ...profile,
          avatarUrl:
            ApiService.resolveImageUrl(profile.avatarUrl ?? null) ??
            profile.avatarUrl ??
            null,
        })
      )
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

  const avatarUrl = user?.avatarUrl ?? null;

  useEffect(() => {
    setAvatarError(false);
  }, [avatarUrl]);

  useEffect(() => {
    if (isClient) {
      setActiveTab("avis");
    }
  }, [isClient]);

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
  <VendorCard
  sellerId={userId}  
    name={user.name}
    avatarUrl={avatarUrl}
    rating={averageRating ? Number(averageRating) : null}
    reviewsCount={reviews.length}
    address={user.address}
    showEditButton={isCurrentUser}
    avatarSize={80}        // tu peux ajuster !
    padding="p-5"          // tu peux réduire si tu veux une version compacte
  />
)}

        {/* ===================== */}
        {/* ✅ TAB BAR */}
        {/* ===================== */}
        <TabMenu
          activeKey={activeTab}
          onChange={setActiveTab}
          tabs={[
            { key: "annonces", label: "Annonces", hidden: isClient },
            { key: "avis", label: "Avis" },
          ]}
        />

        {/* ===================== */}
        {/* ✅ TAB ANNONCES */}
        {/* ===================== */}
        {!isClient && activeTab === "annonces" && (
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
