"use client";

import Link from "next/link";
import { Protected } from "@/src/components/app/Protected";
import { useAuth } from "@/src/context/AuthContext";

export default function DashboardPage() {
  const { user } = useAuth();
  const isSeller = user?.role?.toLowerCase() === "seller";

  return (
    <Protected>
      <div className="max-w-5xl mx-auto px-4 py-10 space-y-4">
        <h1 className="text-2xl font-semibold">Tableau de bord vendeur</h1>
        <p className="text-neutral-600">
          Retrouvez les mêmes entrées que dans l&apos;application Flutter : annonces,
          demandes, commandes.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {isSeller && (
            <Link
              href="/dashboard/listings"
              className="border rounded-xl p-4 shadow-sm hover:shadow"
            >
              <p className="font-semibold">Mes annonces</p>
              <p className="text-sm text-neutral-600">
                Gérez vos articles en ligne.
              </p>
            </Link>
          )}
          <Link
            href="/dashboard/orders/requests"
            className="border rounded-xl p-4 shadow-sm hover:shadow"
          >
            <p className="font-semibold">Demandes</p>
            <p className="text-sm text-neutral-600">
              Acceptez ou refusez les commandes.
            </p>
          </Link>
          <Link
            href="/orders"
            className="border rounded-xl p-4 shadow-sm hover:shadow"
          >
            <p className="font-semibold">Commandes acheteur</p>
            <p className="text-sm text-neutral-600">Suivez vos achats.</p>
          </Link>
        </div>
      </div>
    </Protected>
  );
}
