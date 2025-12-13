"use client";

import ListingCard from "./ListingCard";
import { Listing } from "@/src/models/Listing";
import clsx from "clsx";

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
};

const COL_MAP: Record<number, string> = {
  1: "grid-cols-1",
  2: "grid-cols-2",
  3: "grid-cols-3",
  4: "grid-cols-4",
  5: "grid-cols-5",
  6: "grid-cols-6",
};

export default function ListingsGrid({ listings }: ListingsGridProps) {
  const gridClassName = clsx(
    "grid gap-y-2 gap-x-4 justify-items-stretch",
    "[grid-template-columns:repeat(auto-fill,minmax(180px,1fr))]"
  );

  return (
    <div className={gridClassName}>
      {listings.map((listing) => (
        <ListingCard key={listing.id} listing={listing} />
      ))}
    </div>
  );
}

