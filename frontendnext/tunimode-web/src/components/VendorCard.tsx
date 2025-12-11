"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiService } from "@/src/services/api";

type Props = {
  sellerId: number;
  name?: string;
  avatarUrl?: string | null;
  rating?: number | null;
  reviewsCount?: number;
  address?: string | null;
  showEditButton?: boolean;
  avatarSize?: number;
  padding?: string;
};

export default function VendorCard({
  sellerId,
  name,
  avatarUrl,
  rating,
  reviewsCount,
  address,
  showEditButton = false,
  avatarSize = 80,
  padding = "p-5",
}: Props) {
  const router = useRouter();

  const [avatar, setAvatar] = useState<string | null>(avatarUrl ?? null);
  const [sellerRating, setSellerRating] = useState<number | null>(rating ?? null);
  const [sellerReviews, setSellerReviews] = useState<number>(reviewsCount ?? 0);
  const [sellerAddress, setSellerAddress] = useState<string | null>(address ?? null);
  const [sellerName, setSellerName] = useState<string>(name ?? "");

  // Fetch basic profile + avatar
  useEffect(() => {
    ApiService.fetchUserProfile(sellerId).then((profile) => {
      setSellerName(profile.name);
      setSellerAddress(profile.address ?? null);

      const resolved = ApiService.resolveImageUrl(profile.avatarUrl ?? null);
      setAvatar(resolved);
    });
  }, [sellerId]);


  // FETCH REVIEWS TO COMPUTE RATING  ← MISSING BEFORE
  useEffect(() => {
    ApiService.fetchUserReviews(sellerId).then((reviews) => {
      if (reviews.length === 0) {
        setSellerRating(null);
        setSellerReviews(0);
        return;
      }

      const avg =
        reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

      setSellerRating(Number(avg.toFixed(1)));
      setSellerReviews(reviews.length);
    });
  }, [sellerId]);

  return (
    <div className={`bg-white border rounded-xl shadow-sm flex items-center justify-between ${padding}`}>
      <div className="flex items-center gap-4">
        <div
          className="rounded-full bg-neutral-200 overflow-hidden flex items-center justify-center"
          style={{ width: avatarSize, height: avatarSize }}
        >
          {avatar ? (
            <img src={avatar} className="w-full h-full object-cover" />
          ) : (
            <span className="text-3xl">👤</span>
          )}
        </div>

        <div>
          <h1 className="font-semibold">{sellerName}</h1>

          {sellerRating !== null ? (
            <p className="text-neutral-600">⭐ {sellerRating} / 5 ({sellerReviews} avis)</p>
          ) : (
            <p className="text-neutral-500">Aucun avis</p>
          )}

          <p className="text-neutral-500">📍 {sellerAddress ?? "Adresse non renseignée"}</p>
        </div>
      </div>

      {showEditButton && (
        <button
          onClick={() => router.push("/account/settings")}
          className="px-4 py-2 border rounded-lg text-blue-600 hover:bg-blue-50"
        >
          Modifier profil
        </button>
      )}
    </div>
  );
}
