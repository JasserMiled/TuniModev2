"use client";

import Link from "next/link";
import { useAuth } from "@/src/context/AuthContext";

export function Protected({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  if (!user) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-10 space-y-3">
        <h1 className="text-2xl font-semibold">Espace protégé</h1>
        <p>Connectez-vous pour accéder à cette section.</p>
        <div className="flex gap-3">
          <Link href="/auth/login" className="px-4 py-2 bg-blue-600 text-white rounded-lg">Connexion</Link>
          <Link href="/auth/register" className="px-4 py-2 border border-neutral-300 rounded-lg">Créer un compte</Link>
        </div>
      </div>
    );
  }
  return <>{children}</>;
}
