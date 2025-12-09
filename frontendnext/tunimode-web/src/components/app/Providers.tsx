"use client";

import { AuthProvider } from "@/src/context/AuthContext";
import { SearchProvider } from "@/src/context/SearchContext";

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <SearchProvider>{children}</SearchProvider>
    </AuthProvider>
  );
}
