"use client";

import { useRouter } from "next/navigation";
import { Listing } from "@/src/models/Listing";

type ListingCardProps = {
  listing: Listing;
};

export default function ListingCard({ listing }: ListingCardProps) {
  const router = useRouter();

  return (
    <article
      onClick={() => router.push(`/listings/${listing.id}`)}
      className="border border-neutral-300 rounded-md overflow-hidden shadow-sm hover:shadow-md transition cursor-pointer flex flex-col"
    >
      {/* ✅ IMAGE PLUS HAUTE */}
      <div className="h-62 bg-neutral-100">
        <img
          src={listing.imageUrls?.[0] ?? "/placeholder-listing.svg"}
          alt={listing.title}
          className="w-full h-full object-cover"
        />
      </div>

      {/* ✅ CONTENU LÉGÈREMENT PLUS COMPACT */}
      <div className="p-3 space-y-1">
        <p className="text-sm text-neutral-500">
          {listing.city || "Tunisie"}
        </p>

        <h3 className="font-semibold text-neutral-900 line-clamp-2">
          {listing.title}
        </h3>

        <p className="text-blue-600 font-semibold">
          {listing.price} DT
        </p>
      </div>
    </article>
  );
}
