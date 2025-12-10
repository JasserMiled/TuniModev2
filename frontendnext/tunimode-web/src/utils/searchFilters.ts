import { SearchFilters } from "@/src/context/SearchContext";

const toNumber = (value: string | null): number | undefined => {
  if (value === null || value === "") return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
};

const toList = (value: string | null, fallback: string[] = []) => {
  if (!value) return fallback;
  return value
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);
};

export const buildResultsUrl = (filters: SearchFilters) => {
  const params = new URLSearchParams();

  if (filters.query?.trim()) params.set("query", filters.query.trim());
  if (filters.city) params.set("city", filters.city);
  if (filters.minPrice !== undefined) params.set("min_price", String(filters.minPrice));
  if (filters.maxPrice !== undefined) params.set("max_price", String(filters.maxPrice));
  if (filters.categoryId !== undefined) params.set("category_id", String(filters.categoryId));
  if (filters.sizes?.length) params.set("sizes", filters.sizes.join(","));
  if (filters.colors?.length) params.set("colors", filters.colors.join(","));
  if (filters.deliveryAvailable !== undefined)
    params.set("delivery_available", String(filters.deliveryAvailable));

  const qs = params.toString();
  return qs ? `/search/results?${qs}` : "/search/results";
};

export const filtersFromParams = (
  params: URLSearchParams,
  fallback: SearchFilters
): SearchFilters => {
  const queryParam = params.get("query") ?? params.get("q") ?? fallback.query ?? "";
  const minPrice = toNumber(params.get("min_price") ?? params.get("minPrice"));
  const maxPrice = toNumber(params.get("max_price") ?? params.get("maxPrice"));
  const categoryId = toNumber(params.get("category_id") ?? params.get("categoryId"));
  const city = params.get("city") ?? fallback.city;
  const sizes = toList(params.get("sizes"), fallback.sizes ?? []);
  const colors = toList(params.get("colors"), fallback.colors ?? []);
  const deliveryParam = params.get("delivery_available") ?? params.get("delivery");
  const deliveryAvailable =
    deliveryParam === null ? fallback.deliveryAvailable : deliveryParam === "true";

  return {
    query: queryParam ?? "",
    city: city ?? undefined,
    minPrice: minPrice ?? fallback.minPrice,
    maxPrice: maxPrice ?? fallback.maxPrice,
    categoryId: categoryId ?? fallback.categoryId,
    sizes,
    colors,
    deliveryAvailable,
  };
};

export const toApiFilterParams = (filters: SearchFilters) => ({
  query: filters.query?.trim() || undefined,
  city: filters.city?.trim() || undefined,
  minPrice: filters.minPrice ?? undefined,
  maxPrice: filters.maxPrice ?? undefined,
  categoryId: filters.categoryId ?? undefined,
  sizes: filters.sizes?.length ? filters.sizes : undefined,
  colors: filters.colors?.length ? filters.colors : undefined,
  deliveryAvailable: filters.deliveryAvailable ?? undefined,
});
