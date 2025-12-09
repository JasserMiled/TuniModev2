"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";

export default function OrderDetailPage() {
  const params = useParams<{ id: string }>();
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const id = Number(params?.id);
    if (!id) return;
    ApiService.fetchBuyerOrders()
      .then((list) => list.find((o) => o.id === id))
      .then((found) => {
        if (!found) throw new Error("Commande introuvable");
        setOrder(found);
      })
      .catch((e) => setError(e.message));
  }, [params?.id]);

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
