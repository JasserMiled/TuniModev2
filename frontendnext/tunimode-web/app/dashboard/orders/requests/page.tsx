"use client";

import { useEffect, useState } from "react";
import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";

export default function OrderRequestsPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    ApiService.fetchSellerOrders()
      .then(setOrders)
      .catch((e) => setError(e.message));
  }, []);

  const updateStatus = (id: number, status: string) => {
    ApiService.updateSellerOrderStatus(id, status)
      .then((updated) => setOrders((prev) => prev.map((o) => (o.id === updated.id ? updated : o))))
      .catch((e) => setError(e.message));
  };

  return (
    <Protected>
      <div className="max-w-5xl mx-auto px-4 py-8 space-y-4">
        <h1 className="text-2xl font-semibold">Demandes de commandes</h1>
        {error && <p className="text-red-600">{error}</p>}
        <div className="space-y-3">
          {orders.map((order) => (
            <div key={order.id} className="border rounded-lg p-3 flex items-center justify-between">
              <div>
                <p className="font-semibold">{order.listingTitle}</p>
                <p className="text-sm text-neutral-500">{order.clientName ?? "Client"}</p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => updateStatus(order.id, "accepted")}
                  className="px-3 py-1 bg-blue-600 text-white rounded-lg text-sm"
                >
                  Accepter
                </button>
                <button
                  onClick={() => updateStatus(order.id, "declined")}
                  className="px-3 py-1 border rounded-lg text-sm"
                >
                  Refuser
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Protected>
  );
}
