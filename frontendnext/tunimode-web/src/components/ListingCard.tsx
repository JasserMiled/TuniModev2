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
  onClick={() => router.push(`/listing/${listing.id}`)}
  className="
    border border-neutral-300 rounded-md overflow-hidden
    shadow-sm hover:shadow transition cursor-pointer
    flex flex-col bg-white w-full
    max-w-full
    min-h-[280px]
	m-1   
  "
>

      {/* IMAGE */}
      <div className="aspect-[4/5] bg-neutral-100">
        <img
          src={listing.imageUrl || '/placeholder-listing.svg'}
          alt={listing.title}
          className="w-full h-full object-cover"
        />
      </div>

      {/* CONTENT */}
      <div className="p-2 flex flex-col flex-grow justify-between">
        <div>
          <p className="text-xs text-neutral-500">
            {listing.city || "Tunisie"}
          </p>

          <h3 className="font-medium text-sm text-neutral-900 line-clamp-2">
            {listing.title}
          </h3>
        </div>

        <p className="text-blue-700 font-semibold text-base mt-1">
          {listing.price} DT
        </p>
      </div>
    </article>
  );
}
