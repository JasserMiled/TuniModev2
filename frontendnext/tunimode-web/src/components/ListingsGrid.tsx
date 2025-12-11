"use client";

import { useRouter } from "next/navigation";
import ListingCard from "./ListingCard";
import { Listing } from "@/src/models/Listing";

type BreakpointConfig = {
  base?: number;
  sm?: number;
  md?: number;
  lg?: number;
  xl?: number;
};

type ListingsGridProps = {
  listings: Listing[];
  columns: BreakpointConfig;
  rows: BreakpointConfig;
  renderOverlay?: (listing: Listing) => React.ReactNode;
};

export default function ListingsGrid({
  listings,
  columns,
  rows,
  renderOverlay,
}: ListingsGridProps) {
  const router = useRouter();

  // Generate grid classes dynamically
  const gridClasses = `
    grid gap-4
    grid-cols-${columns.base ?? 2}
    sm:grid-cols-${columns.sm ?? columns.base ?? 2}
    md:grid-cols-${columns.md ?? columns.sm ?? columns.base ?? 2}
    lg:grid-cols-${columns.lg ?? columns.md ?? columns.sm ?? columns.base ?? 2}
  `;

  return (
    <div className={gridClasses}>
      {listings.map((listing) => (
        <div
          key={listing.id}
          className="relative cursor-pointer"
          onClick={() => router.push(`/listing/${listing.id}`)}
        >
          {/* The actual card */}
          <ListingCard listing={listing} />

          {/* ❤️ Overlay button if provided */}
          {renderOverlay && (
            <div className="absolute top-2 right-2 z-20">
              {renderOverlay(listing)}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
