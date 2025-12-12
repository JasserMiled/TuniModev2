"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";
import AppHeader from "@/src/components/AppHeader";
import { useAuth } from "@/src/context/AuthContext";
import TabMenu from "@/src/components/TabMenu";

export default function OrdersPage() {
  const { user } = useAuth();
  const [clientOrders, setClientOrders] = useState<Order[]>([]);
  const [sellerOrders, setSellerOrders] = useState<Order[]>([]);
  const [activeTab, setActiveTab] = useState<"seller" | "client">("seller");
  const [error, setError] = useState<string | null>(null);

  const [sellerStatusFilter, setSellerStatusFilter] = useState<string | null>(null);
  const [clientStatusFilter, setClientStatusFilter] = useState<string | null>(null);

  const router = useRouter();

  const isSeller = user?.role === "seller";
  const isClient = user?.role === "client";

  // ✅ LOAD DATA
  const loadOrders = async () => {
    try {
      const [seller, client] = await Promise.all<[
        Order[] | undefined,
        Order[] | undefined
      ]>([
        isSeller ? ApiService.fetchSellerOrders() : Promise.resolve(undefined),
        isClient ? ApiService.fetchClientOrders() : Promise.resolve(undefined),
      ]);

      setSellerOrders(seller ?? []);
      setClientOrders(client ?? []);
    } catch (e: any) {
      setError(e.message);
    }
  };

  useEffect(() => {
    if (isSeller) setActiveTab("seller");
    if (isClient && !isSeller) setActiveTab("client");
    loadOrders();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isSeller, isClient]);

  // ✅ STATUS LABEL
  const statusLabel = (status: string) => {
    switch (status) {
      case "confirmed": return "Confirmée";
      case "shipped": return "Expédiée";
      case "delivred": return "Livrée";
      case "ready_for_pickup": return "À retirer";
      case "picked_up": return "Retirée";
      case "received": return "Reçue";
      case "reception_refused": return "Réception refusée";
      case "completed": return "Terminée";
      case "cancelled": return "Annulée";
      default: return "En attente";
    }
  };

  // ✅ STATUS COLOR
  const statusColor = (status: string) => {
    switch (status) {
      case "confirmed": return "bg-blue-100 text-blue-700";
      case "shipped": return "bg-purple-100 text-purple-700";
      case "delivred": return "bg-indigo-100 text-indigo-700";
      case "ready_for_pickup": return "bg-orange-100 text-orange-700";
      case "picked_up": return "bg-teal-100 text-teal-700";
      case "received": return "bg-green-100 text-green-700";
      case "reception_refused": return "bg-red-100 text-red-700";
      case "completed": return "bg-emerald-100 text-emerald-700";
      case "cancelled": return "bg-red-100 text-red-700";
      default: return "bg-orange-100 text-orange-700";
    }
  };

  // ✅ FILTER
  const applyFilter = (orders: Order[], status: string | null) => {
    if (!status) return orders;
    return orders.filter((o) => o.status === status);
  };

  const sellerFiltered = applyFilter(sellerOrders, sellerStatusFilter);
  const clientFiltered = applyFilter(clientOrders, clientStatusFilter);

  return (
    <Protected>
      <main className="bg-gray-50 min-h-screen">
        <AppHeader />

        <div className="max-w-5xl mx-auto px-4 py-8">
          <h1 className="text-2xl font-semibold mb-6">Mes commandes</h1>

          {error && <p className="text-red-600">{error}</p>}

          <TabMenu
            className="mb-6"
            activeKey={activeTab}
            onChange={setActiveTab}
            tabs={[
              { key: "seller", label: "Ventes", hidden: !isSeller },
              { key: "client", label: "Achats (client)", hidden: !isClient },
            ]}
          />

          {/* ✅ FILTER */}
          <div className="mb-4">
            <select
              className="border rounded-lg px-3 py-2 w-full"
              value={
                activeTab === "seller"
                  ? sellerStatusFilter ?? ""
                  : clientStatusFilter ?? ""
              }
              onChange={(e) =>
                activeTab === "seller"
                  ? setSellerStatusFilter(e.target.value || null)
                  : setClientStatusFilter(e.target.value || null)
              }
            >
              <option value="">Tous les statuts</option>
              {[...new Set(
                (activeTab === "seller" ? sellerOrders : clientOrders).map(
                  (o) => o.status
                )
              )].map((status) => (
                <option key={status} value={status}>
                  {statusLabel(status)}
                </option>
              ))}
            </select>
          </div>

          {/* ✅ LIST */}
          {(activeTab === "seller" ? sellerFiltered : clientFiltered).map(
            (order) => (
              <div
                key={order.id}
                className="bg-gray-100 rounded-xl p-4 mb-4 flex justify-between items-start hover:shadow cursor-pointer"
                onClick={() => router.push(`/orders/${order.id}`)}
              >
                <div>
                  <p className="font-semibold">{order.listingTitle}</p>

                  <p className="text-sm text-gray-600">
                    Statut : {statusLabel(order.status)} • Mode :{" "}
                    {order.receptionMode === "livraison"
                      ? "Livraison"
                      : "Retrait sur place"}{" "}
                    • Quantité : {order.quantity}
                  </p>

                  {order.shippingAddress && (
                    <p className="text-sm">
                      Adresse : {order.shippingAddress}
                    </p>
                  )}

                  {order.phone && (
                    <p className="text-sm">
                      Téléphone : {order.phone}
                    </p>
                  )}

                  {/* ✅ CLIENT ACTIONS */}
                  {activeTab === "client" && order.status === "pending" && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        ApiService.cancelOrder(order.id).then(loadOrders);
                      }}
                      className="mt-2 border border-red-500 text-red-600 px-3 py-1 rounded-lg"
                    >
                      Annuler la commande
                    </button>
                  )}

                  {/* ✅ SELLER ACTIONS */}
                  {activeTab === "seller" && order.status === "pending" && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        ApiService.updateSellerOrderStatus(order.id, "confirmed")
                          .then(loadOrders);
                      }}
                      className="mt-2 bg-blue-600 text-white px-3 py-1 rounded-lg"
                    >
                      Confirmer la commande
                    </button>
                  )}

                  {activeTab === "seller" &&
                    ["confirmed", "shipped", "ready_for_pickup"].includes(
                      order.status
                    ) && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          ApiService.updateSellerOrderStatus(
                            order.id,
                            "cancelled"
                          ).then(loadOrders);
                        }}
                        className="mt-2 border border-red-500 text-red-600 px-3 py-1 rounded-lg"
                      >
                        Annuler la commande
                      </button>
                    )}
                </div>

                <div className="text-right">
                  <p className="font-semibold">
                    {Number(order.totalAmount || 0).toFixed(2)} TND



                  </p>

                  <span
                    className={`inline-block mt-2 px-3 py-1 rounded-full text-xs font-semibold ${statusColor(
                      order.status
                    )}`}
                  >
                    {statusLabel(order.status)}
                  </span>
                </div>
              </div>
            )
          )}
        </div>
      </main>
    </Protected>
  );
}
