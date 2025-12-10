"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";
import AppHeader from "@/src/components/AppHeader";
import { useAuth } from "@/src/context/AuthContext";

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

  const extractError = (e: unknown) =>
    e instanceof Error ? e.message : "Une erreur est survenue";

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
    } catch (e) {
      setError(extractError(e));
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
      case "ready_for_pickup": return "À retirer";
      case "picked_up": return "Retirée";
      case "received": return "Reçue";
      case "completed": return "Terminée";
      case "cancelled": return "Annulée";
      case "refused": return "Refusée";
      case "reception_refused": return "Réception refusée";
      default: return "En attente";
    }
  };

  // ✅ STATUS COLOR
  const statusColor = (status: string) => {
    switch (status) {
      case "confirmed": return "bg-blue-100 text-blue-700";
      case "shipped": return "bg-purple-100 text-purple-700";
      case "ready_for_pickup": return "bg-orange-100 text-orange-700";
      case "picked_up": return "bg-teal-100 text-teal-700";
      case "received": return "bg-green-100 text-green-700";
      case "completed": return "bg-emerald-100 text-emerald-700";
      case "cancelled":
      case "refused":
      case "reception_refused":
        return "bg-red-100 text-red-700";
      default: return "bg-orange-100 text-orange-700";
    }
  };

  const updateSellerStatus = async (orderId: number, status: string) => {
    try {
      await ApiService.updateSellerOrderStatus(orderId, status);
      await loadOrders();
    } catch (e) {
      setError(extractError(e));
    }
  };

  const cancelClientOrder = async (orderId: number) => {
    try {
      await ApiService.cancelOrder(orderId);
      await loadOrders();
    } catch (e) {
      setError(extractError(e));
    }
  };

  const clientReceptionAction = async (
    orderId: number,
    action: "receive" | "refuse"
  ) => {
    try {
      if (action === "receive") {
        await ApiService.confirmOrderReception(orderId);
      } else {
        await ApiService.refuseOrderReception(orderId);
      }
      await loadOrders();
    } catch (e) {
      setError(extractError(e));
    }
  };

  const renderSellerActions = (order: Order) => {
    if (activeTab !== "seller") return null;

    switch (order.status) {
      case "pending":
        return (
          <div className="flex flex-wrap gap-2 mt-2">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "confirmed");
              }}
              className="bg-blue-600 text-white px-3 py-1 rounded-lg"
            >
              Confirmer la commande
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "refused");
              }}
              className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
            >
              Refuser
            </button>
          </div>
        );
      case "confirmed":
        return (
          <div className="flex flex-wrap gap-2 mt-2">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "shipped");
              }}
              className="bg-purple-600 text-white px-3 py-1 rounded-lg"
            >
              Marquer expédiée
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "ready_for_pickup");
              }}
              className="border border-orange-500 text-orange-600 px-3 py-1 rounded-lg"
            >
              Mettre à retirer
            </button>
          </div>
        );
      case "ready_for_pickup":
        return (
          <div className="flex flex-wrap gap-2 mt-2">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "picked_up");
              }}
              className="bg-teal-600 text-white px-3 py-1 rounded-lg"
            >
              Marquer retirée
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "cancelled");
              }}
              className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
            >
              Annuler
            </button>
          </div>
        );
      case "picked_up":
        return (
          <div className="flex flex-wrap gap-2 mt-2">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateSellerStatus(order.id, "completed");
              }}
              className="bg-emerald-600 text-white px-3 py-1 rounded-lg"
            >
              Terminer
            </button>
          </div>
        );
      default:
        return null;
    }
  };

  const renderClientActions = (order: Order) => {
    if (activeTab !== "client") return null;

    if (order.status === "pending") {
      return (
        <div className="mt-2">
          <button
            onClick={(e) => {
              e.stopPropagation();
              cancelClientOrder(order.id);
            }}
            className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
          >
            Annuler la commande
          </button>
        </div>
      );
    }

    if (order.status === "shipped") {
      return (
        <div className="flex flex-wrap gap-2 mt-2">
          <button
            onClick={(e) => {
              e.stopPropagation();
              clientReceptionAction(order.id, "receive");
            }}
            className="bg-green-600 text-white px-3 py-1 rounded-lg"
          >
            Confirmer la réception
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              clientReceptionAction(order.id, "refuse");
            }}
            className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
          >
            Refuser la réception
          </button>
        </div>
      );
    }

    return null;
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

          {/* ✅ TAB BAR */}
          <div className="flex border-b mb-6">
            {isSeller && (
              <button
                onClick={() => setActiveTab("seller")}
                className={`px-6 py-2 font-semibold ${
                  activeTab === "seller"
                    ? "border-b-2 border-blue-600 text-blue-600"
                    : "text-gray-500"
                }`}
              >
                Ventes
              </button>
            )}

            {isClient && (
              <button
                onClick={() => setActiveTab("client")}
                className={`px-6 py-2 font-semibold ${
                  activeTab === "client"
                    ? "border-b-2 border-blue-600 text-blue-600"
                    : "text-gray-500"
                }`}
              >
                Achats (client)
              </button>
            )}
          </div>

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

                  {/* ✅ ACTIONS */}
                  {renderClientActions(order)}
                  {renderSellerActions(order)}
                </div>

                <div className="text-right">
                  <p className="font-semibold">
                    {(order.totalAmount ?? 0).toFixed(2)} TND

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
