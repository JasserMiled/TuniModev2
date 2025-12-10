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

  /** Colonnes par breakpoint */
  columns?: BreakpointConfig;

  /** Lignes par breakpoint */
  rows?: BreakpointConfig;
};

export default function ListingsGrid({
  listings,
  columns = { base: 2, sm: 3, md: 4, lg: 5 },
  rows = { base: 2, sm: 2, md: 2, lg: 2 },
}: ListingsGridProps) {
  if (listings.length === 0) {
    return <p className="text-neutral-500 py-6">Aucune annonce trouvée.</p>;
  }

  // ✅ Nombre total d’items à afficher (desktop en priorité)
  const maxItems =
    (columns.lg || columns.md || columns.base || 2) *
    (rows.lg || rows.md || rows.base || 2);

  const visibleListings = listings.slice(0, maxItems);

  // ✅ Classes Tailwind SAFES (aucune dynamique cassée)
  const gridClasses = [
    "grid gap-4",

    columns.base === 1 && "grid-cols-1",
    columns.base === 2 && "grid-cols-2",
    columns.base === 3 && "grid-cols-3",
    columns.base === 4 && "grid-cols-4",
    columns.base === 5 && "grid-cols-5",

    columns.sm === 1 && "sm:grid-cols-1",
    columns.sm === 2 && "sm:grid-cols-2",
    columns.sm === 3 && "sm:grid-cols-3",
    columns.sm === 4 && "sm:grid-cols-4",
    columns.sm === 5 && "sm:grid-cols-5",

    columns.md === 1 && "md:grid-cols-1",
    columns.md === 2 && "md:grid-cols-2",
    columns.md === 3 && "md:grid-cols-3",
    columns.md === 4 && "md:grid-cols-4",
    columns.md === 5 && "md:grid-cols-5",

    columns.lg === 1 && "lg:grid-cols-1",
    columns.lg === 2 && "lg:grid-cols-2",
    columns.lg === 3 && "lg:grid-cols-3",
    columns.lg === 4 && "lg:grid-cols-4",
    columns.lg === 5 && "lg:grid-cols-5",

    columns.xl === 1 && "xl:grid-cols-1",
    columns.xl === 2 && "xl:grid-cols-2",
    columns.xl === 3 && "xl:grid-cols-3",
    columns.xl === 4 && "xl:grid-cols-4",
    columns.xl === 5 && "xl:grid-cols-5",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={gridClasses}>
      {visibleListings.map((listing) => (
        <ListingCard key={listing.id} listing={listing} />
      ))}
    </div>
  );
}
