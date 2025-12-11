"use client";

import { KeyboardEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiService } from "@/src/services/api";

type Props = {
  clientId: number;
  name?: string;
  avatarUrl?: string | null;
  rating?: number | null;
  reviewsCount?: number;
  address?: string | null;
  avatarSize?: number;
  padding?: string;
};

export default function ClientCard({
  clientId,
  name,
  avatarUrl,
  rating,
  reviewsCount,
  address,
  avatarSize = 80,
  padding = "p-5",
}: Props) {
  const router = useRouter();

  const [avatar, setAvatar] = useState<string | null>(avatarUrl ?? null);
  const [clientRating, setClientRating] = useState<number | null>(rating ?? null);
  const [clientReviews, setClientReviews] = useState<number>(reviewsCount ?? 0);
  const [clientAddress, setClientAddress] = useState<string | null>(address ?? null);
  const [clientName, setClientName] = useState<string>(name ?? "");

  // Fetch basic profile + avatar
  useEffect(() => {
    ApiService.fetchUserProfile(clientId).then((profile) => {
      setClientName(profile.name);
      setClientAddress(profile.address ?? null);

      const resolved = ApiService.resolveImageUrl(profile.avatarUrl ?? null);
      setAvatar(resolved);
    });
  }, [clientId]);

  // FETCH REVIEWS TO COMPUTE RATING
  useEffect(() => {
    ApiService.fetchUserReviews(clientId).then((reviews) => {
      if (reviews.length === 0) {
        setClientRating(null);
        setClientReviews(0);
        return;
      }

      const avg = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

      setClientRating(Number(avg.toFixed(1)));
      setClientReviews(reviews.length);
    });
  }, [clientId]);

  const goToClientProfile = () => {
    router.push(`/profile/${clientId}`);
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      goToClientProfile();
    }
  };

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={goToClientProfile}
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
          <h1 className="font-semibold">{clientName}</h1>
          {clientRating !== null ? (
            <p className="text-neutral-600">⭐ {clientRating} / 5 ({clientReviews} avis)</p>
          ) : (
            <p className="text-neutral-500">Aucun avis</p>
          )}
          <p className="text-neutral-500">
            📍 {clientAddress ?? "Adresse non renseignée"}
          </p>
        </div>
      </div>
    </div>
  );
}
