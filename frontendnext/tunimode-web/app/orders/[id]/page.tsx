"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { Order } from "@/src/models/Order";
import { Protected } from "@/src/components/app/Protected";
import { useAuth } from "@/src/context/AuthContext";
import ListingCard from "@/src/components/ListingCard";
import { Listing } from "@/src/models/Listing";
import ClientCard from "@/src/components/ClientCard";
import AppHeader from "@/src/components/AppHeader";

export default function OrderDetailPage() {
  const params = useParams<{ id: string }>();
  const { user } = useAuth();
  const [order, setOrder] = useState<Order | null>(null);
  const [listing, setListing] = useState<Listing | null>(null);
  const [error, setError] = useState<string | null>(null);

  const extractError = (e: unknown) =>
    e instanceof Error ? e.message : "Une erreur est survenue";

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

  const loadOrder = async () => {
    const id = Number(params?.id);
    if (!id || !user?.role) return;
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
      setListing(null);
      setError(null);
    } catch (e) {
      setError(extractError(e));
    }
  };

  useEffect(() => {
    loadOrder();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params?.id, user?.role]);

  useEffect(() => {
    const fetchListing = async () => {
      if (!order?.listingId || user?.role !== "seller") return;
      try {
        const listingDetail = await ApiService.fetchListingDetail(order.listingId);
        setListing(listingDetail);
      } catch (e) {
        setError(extractError(e));
      }
    };

    fetchListing();
  }, [order?.listingId, user?.role]);

  const updateSellerStatus = async (status: string) => {
    if (!order) return;
    try {
      await ApiService.updateSellerOrderStatus(order.id, status);
      await loadOrder();
    } catch (e) {
      setError(extractError(e));
    }
  };

  const cancelClientOrder = async () => {
    if (!order) return;
    try {
      await ApiService.cancelOrder(order.id);
      await loadOrder();
    } catch (e) {
      setError(extractError(e));
    }
  };

  const clientReceptionAction = async (action: "receive" | "refuse") => {
    if (!order) return;
    try {
      if (action === "receive") {
        await ApiService.confirmOrderReception(order.id);
      } else {
        await ApiService.refuseOrderReception(order.id);
      }
      await loadOrder();
    } catch (e) {
      setError(extractError(e));
    }
  };

  const renderActions = () => {
    if (!order || !user?.role) return null;

    if (user.role === "seller") {
      switch (order.status) {
        case "pending":
          return (
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => updateSellerStatus("confirmed")}
                className="bg-blue-600 text-white px-3 py-1 rounded-lg"
              >
                Confirmer
              </button>
              <button
                onClick={() => updateSellerStatus("refused")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Refuser
              </button>
            </div>
          );
        case "confirmed":
          return (
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => updateSellerStatus("shipped")}
                className="bg-purple-600 text-white px-3 py-1 rounded-lg"
              >
                Marquer expédiée
              </button>
              <button
                onClick={() => updateSellerStatus("ready_for_pickup")}
                className="border border-orange-500 text-orange-600 px-3 py-1 rounded-lg"
              >
                Mettre à retirer
              </button>
            </div>
          );
        case "ready_for_pickup":
          return (
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => updateSellerStatus("picked_up")}
                className="bg-teal-600 text-white px-3 py-1 rounded-lg"
              >
                Marquer retirée
              </button>
              <button
                onClick={() => updateSellerStatus("cancelled")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Annuler
              </button>
            </div>
          );
        case "picked_up":
          return (
            <button
              onClick={() => updateSellerStatus("completed")}
              className="bg-emerald-600 text-white px-3 py-1 rounded-lg"
            >
              Terminer
            </button>
          );
        default:
          return null;
      }
    }

    if (user.role === "client") {
      if (order.status === "pending") {
        return (
          <button
            onClick={cancelClientOrder}
            className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
          >
            Annuler la commande
          </button>
        );
      }

      if (order.status === "shipped") {
        return (
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => clientReceptionAction("receive")}
              className="bg-green-600 text-white px-3 py-1 rounded-lg"
            >
              Confirmer la réception
            </button>
            <button
              onClick={() => clientReceptionAction("refuse")}
              className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
            >
              Refuser la réception
            </button>
          </div>
        );
      }
    }

    return null;
  };

  return (
    <Protected>
      <main className="bg-gray-50 min-h-screen">
        <AppHeader />

        <div className="max-w-3xl mx-auto px-4 py-8 space-y-3">
          {error && <p className="text-red-600">{error}</p>}
          {!order && !error && <p>Chargement...</p>}
          {order && (
            <>
              <h1 className="text-2xl font-semibold">Commande #{order.id}</h1>
              <p className="text-neutral-600">{order.listingTitle}</p>
              <p className="font-semibold text-blue-600">{order.totalAmount} DT</p>

              <div className="flex items-center gap-3">
                <span
                  className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColor(
                    order.status
                  )}`}
                >
                  {statusLabel(order.status)}
                </span>
                <span className="text-sm text-gray-600">
                  Mode : {order.receptionMode === "livraison" ? "Livraison" : "Retrait"}
                </span>
              </div>

              <p>Quantité : {order.quantity}</p>

              {order.shippingAddress && (
                <p>Adresse : {order.shippingAddress}</p>
              )}

              {order.phone && <p>Téléphone : {order.phone}</p>}

              {user?.role === "seller" && (
                <div className="space-y-3 pt-4 border-t">
                  <p className="font-semibold">Informations client</p>
                  {order.clientId ? (
                    <ClientCard clientId={order.clientId} padding="p-4" avatarSize={64} />
                  ) : (
                    <p className="text-sm text-gray-600">Client introuvable.</p>
                  )}

                  <p className="font-semibold">Annonce commandée</p>
                  {listing ? (
                    <ListingCard listing={listing} />
                  ) : (
                    <p className="text-sm text-gray-600">Annonce introuvable.</p>
                  )}
                </div>
              )}

              <div className="pt-4 border-t space-y-2">
                <p className="font-semibold">Actions disponibles</p>
                {renderActions() ?? (
                  <p className="text-sm text-gray-600">Aucune action disponible.</p>
                )}
              </div>
            </>
          )}
        </div>
      </main>
    </Protected>
  );
}
