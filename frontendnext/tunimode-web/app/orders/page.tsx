"use client";

import { useEffect, useState } from "react";
import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";
import { useRouter } from "next/navigation";

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    ApiService.fetchBuyerOrders()
      .then(setOrders)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <Protected>
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-4">
        <h1 className="text-2xl font-semibold">Mes commandes</h1>
        {error && <p className="text-red-600">{error}</p>}
        <div className="space-y-3">
          {orders.map((order) => (
            <div
              key={order.id}
              className="border rounded-lg p-3 flex items-center justify-between cursor-pointer"
              onClick={() => router.push(`/orders/${order.id}`)}
            >
              <div>
                <p className="font-semibold">{order.listingTitle}</p>
                <p className="text-sm text-neutral-500">{order.status}</p>
              </div>
              <div className="text-right">
                <p className="font-semibold">{order.totalAmount} DT</p>
                <p className="text-sm">Quantité : {order.quantity}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Protected>
  );
}
