"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";
import { useAuth } from "@/src/context/AuthContext";

export default function OrderDetailPage() {
  const params = useParams<{ id: string }>();
  const { user } = useAuth();
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const id = Number(params?.id);
    if (!id) return;
    if (!user?.role) return;
    const load = async () => {
      try {
        const isClient = user?.role === "client";
        const isSeller = user?.role === "seller";
        const list = isClient
          ? await ApiService.fetchClientOrders()
          : isSeller
            ? await ApiService.fetchSellerOrders()
            : [];
        const found = list.find((o) => o.id === id);
        if (!found) throw new Error("Commande introuvable");
        setOrder(found);
      } catch (e: any) {
        setError(e.message);
      }
    };
    load();
  }, [params?.id, user?.role]);

  return (
    <Protected>
      <div className="max-w-3xl mx-auto px-4 py-8 space-y-3">
        {error && <p className="text-red-600">{error}</p>}
        {!order && !error && <p>Chargement...</p>}
        {order && (
          <>
            <h1 className="text-2xl font-semibold">Commande #{order.id}</h1>
            <p className="text-neutral-600">{order.listingTitle}</p>
            <p className="font-semibold text-blue-600">{order.totalAmount} DT</p>
            <p>Statut : {order.status}</p>
            <p>Mode de réception : {order.receptionMode}</p>
            <p>Quantité : {order.quantity}</p>
          </>
        )}
      </div>
    </Protected>
  );
}
