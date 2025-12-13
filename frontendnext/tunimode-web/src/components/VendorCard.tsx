"use client";

import { KeyboardEvent, useEffect, useState } from "react";
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
  const [sellerDescription, setSellerDescription] = useState<string | null>(null);
  const [showDescriptionOnCard, setShowDescriptionOnCard] = useState<boolean>(false);

  // Fetch basic profile + avatar
  useEffect(() => {
    ApiService.fetchUserProfile(sellerId).then((profile) => {
      setSellerName(profile.name);
      setSellerAddress(profile.address ?? null);
      setSellerDescription(profile.description ?? null);
      setShowDescriptionOnCard(profile.showDescriptionOnCard ?? false);

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

  const goToSellerProfile = () => {
    router.push(`/profile/${sellerId}`);
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      goToSellerProfile();
    }
  };

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={goToSellerProfile}
      onKeyDown={handleKeyDown}
      className={`bg-white rounded-xl shadow-md flex items-center justify-between ${padding} cursor-pointer`}
    >
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

          <p className="text-neutral-500">
            📍 {sellerAddress ?? "Adresse non renseignée"}
          </p>

          {showDescriptionOnCard && sellerDescription && (
            <p className="text-neutral-700 text-sm mt-2 line-clamp-2 whitespace-pre-line">
              {sellerDescription}
            </p>
          )}
        </div>
      </div>

      {showEditButton && (
        <button
          onClick={(event) => {
            event.stopPropagation();
            router.push("/account/settings");
          }}
          className="px-4 py-2 border rounded-lg text-blue-600 hover:bg-blue-50"
        >
          Modifier profil
        </button>
      )}
    </div>
  );
}
