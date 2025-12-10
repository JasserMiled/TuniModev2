"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from "react";

export type SearchFilters = {
  query: string;
  gender?: string;
  city?: string;
  minPrice?: number;
  maxPrice?: number;
  categoryId?: number;
  sizes?: string[];
  colors?: string[];
  deliveryAvailable?: boolean;
};

type SearchState = {
  lastSearch: SearchFilters;
  setSearch: (filters: SearchFilters) => void;
};

const defaultFilters: SearchFilters = { query: "" };

const SearchContext = createContext<SearchState | undefined>(undefined);

export const SearchProvider = ({ children }: { children: React.ReactNode }) => {
  const [lastSearch, setLastSearch] = useState<SearchFilters>(defaultFilters);

  const setSearch = useCallback((filters: SearchFilters) => {
    setLastSearch({ ...filters });
  }, []);

  const value = useMemo(() => ({ lastSearch, setSearch }), [lastSearch, setSearch]);

  return <SearchContext.Provider value={value}>{children}</SearchContext.Provider>;
};

export const useSearch = () => {
  const ctx = useContext(SearchContext);
  if (!ctx) throw new Error("useSearch must be used within SearchProvider");
  return ctx;
};
