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
import VendorCard from "@/src/components/VendorCard";
import { Review } from "@/src/models/Review";

export default function OrderDetailPage() {
  const params = useParams<{ id: string }>();
  const { user } = useAuth();
  const [order, setOrder] = useState<Order | null>(null);
  const [listing, setListing] = useState<Listing | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [reviewsError, setReviewsError] = useState<string | null>(null);
  const [isSubmittingReview, setIsSubmittingReview] = useState(false);
  const [showReviewForm, setShowReviewForm] = useState(false);
  const [reviewRating, setReviewRating] = useState(5);
  const [reviewComment, setReviewComment] = useState("");

  const extractError = (e: unknown) =>
    e instanceof Error ? e.message : "Une erreur est survenue";

  const statusLabel = (status: string) => {
    switch (status) {
      case "confirmed": return "Confirmée";
      case "shipped": return "Expédiée";
      case "delivred": return "Livrée";
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
      case "delivred": return "bg-indigo-100 text-indigo-700";
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
      if (!order?.listingId) return;
      try {
        const listingDetail = await ApiService.fetchListingDetail(order.listingId);
        setListing(listingDetail);
      } catch (e) {
        setError(extractError(e));
      }
    };

    fetchListing();
  }, [order?.listingId, user?.role]);

  useEffect(() => {
    const loadReviews = async () => {
      if (!order?.id) return;
      try {
        const fetched = await ApiService.fetchOrderReviews(order.id);
        setReviews(fetched);
        setReviewsError(null);
      } catch (e) {
        setReviewsError(extractError(e));
      }
    };

    loadReviews();
  }, [order?.id]);

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
                onClick={() => updateSellerStatus("cancelled")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Annuler
              </button>
            </div>
          );
        case "confirmed":
          return (
            <div className="flex flex-wrap gap-2">
              {order.receptionMode === "livraison" && (
                <button
                  onClick={() => updateSellerStatus("shipped")}
                  className="bg-purple-600 text-white px-3 py-1 rounded-lg"
                >
                  Marquer expédiée
                </button>
              )}
              {order.receptionMode === "retrait" && (
                <button
                  onClick={() => updateSellerStatus("ready_for_pickup")}
                  className="border border-orange-500 text-orange-600 px-3 py-1 rounded-lg"
                >
                  Mettre à retirer
                </button>
              )}
              <button
                onClick={() => updateSellerStatus("cancelled")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Annuler
              </button>
            </div>
          );
        case "shipped":
          return (
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => updateSellerStatus("delivred")}
                className="bg-indigo-600 text-white px-3 py-1 rounded-lg"
              >
                Marquer livrée
              </button>
              <button
                onClick={() => updateSellerStatus("reception_refused")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Refus de réception
              </button>
              <button
                onClick={() => updateSellerStatus("cancelled")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Annuler
              </button>
            </div>
          );
        case "delivred":
          return (
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => updateSellerStatus("reception_refused")}
                className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
              >
                Refus de réception
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
        case "received":
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

      if (["shipped", "delivred", "received"].includes(order.status)) {
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
            <button
              onClick={cancelClientOrder}
              className="border border-red-500 text-red-600 px-3 py-1 rounded-lg"
            >
              Annuler la commande
            </button>
          </div>
        );
      }
    }

    return null;
  };

  const eligibleForReviewStatuses = new Set([
    "confirmed",
    "shipped",
    "ready_for_pickup",
    "picked_up",
    "received",
    "completed",
  ]);

  const canEvaluate = Boolean(
    order && user && eligibleForReviewStatuses.has(order.status)
  );

  const hasLeftReview = Boolean(
    user && reviews.some((review) => review.reviewerId === user.id)
  );

  const submitReview = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!order) return;
    setIsSubmittingReview(true);
    try {
      await ApiService.submitReview({
        orderId: order.id,
        rating: reviewRating,
        comment: reviewComment.trim() || undefined,
      });
      const refreshed = await ApiService.fetchOrderReviews(order.id);
      setReviews(refreshed);
      setShowReviewForm(false);
      setReviewComment("");
      setReviewRating(5);
      setReviewsError(null);
    } catch (e) {
      setReviewsError(extractError(e));
    } finally {
      setIsSubmittingReview(false);
    }
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

              {user?.role === "client" && (
                <div className="space-y-3 pt-4 border-t">
                  <p className="font-semibold">Annonce commandée</p>
                  {listing ? (
                    <ListingCard listing={listing} />
                  ) : (
                    <p className="text-sm text-gray-600">Annonce introuvable.</p>
                  )}

                  <p className="font-semibold">Vendeur</p>
                  {order.sellerId ? (
                    <VendorCard
                      sellerId={order.sellerId}
                      name={order.sellerName ?? undefined}
                      padding="p-4"
                      avatarSize={64}
                    />
                  ) : (
                    <p className="text-sm text-gray-600">Vendeur introuvable.</p>
                  )}
                </div>
              )}

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

              <div className="pt-4 border-t space-y-3">
                <div className="flex items-center justify-between">
                  <p className="font-semibold">Évaluations</p>
                  {canEvaluate && !hasLeftReview && (
                    <button
                      onClick={() => setShowReviewForm((prev) => !prev)}
                      className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700"
                    >
                      {showReviewForm ? "Fermer" : "Ajouter une évaluation"}
                    </button>
                  )}
                </div>

                {canEvaluate && hasLeftReview && (
                  <p className="text-sm text-green-700">
                    Vous avez déjà évalué cette commande.
                  </p>
                )}

                {canEvaluate && showReviewForm && !hasLeftReview && (
                  <form onSubmit={submitReview} className="space-y-3 bg-white p-4 rounded-xl shadow-sm border">
                    <div>
                      <label className="block text-sm font-medium mb-1">
                        Note (1 à 5)
                      </label>
                      <select
                        value={reviewRating}
                        onChange={(e) => setReviewRating(Number(e.target.value))}
                        className="w-full rounded-lg border border-gray-300 px-3 py-2"
                      >
                        {[1, 2, 3, 4, 5].map((value) => (
                          <option key={value} value={value}>
                            {value}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium mb-1">
                        Votre message d'évaluation
                      </label>
                      <textarea
                        value={reviewComment}
                        onChange={(e) => setReviewComment(e.target.value)}
                        className="w-full rounded-lg border border-gray-300 px-3 py-2"
                        rows={4}
                        placeholder="Partagez votre expérience avec votre interlocuteur"
                        required
                      />
                    </div>

                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        onClick={() => setShowReviewForm(false)}
                        className="px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-100"
                      >
                        Annuler
                      </button>
                      <button
                        type="submit"
                        disabled={isSubmittingReview}
                        className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
                      >
                        {isSubmittingReview ? "Envoi..." : "Envoyer l'évaluation"}
                      </button>
                    </div>
                  </form>
                )}

                {reviewsError && (
                  <p className="text-sm text-red-600">{reviewsError}</p>
                )}

                <div className="space-y-2">
                  {reviews.length === 0 ? (
                    <p className="text-sm text-gray-600">
                      Aucun avis pour le moment.
                    </p>
                  ) : (
                    reviews.map((review) => (
                      <div
                        key={review.id}
                        className="bg-white p-4 rounded-xl shadow-sm border"
                      >
                        <div className="flex items-center justify-between">
                          <p className="font-semibold">
                            {review.reviewerName ?? "Utilisateur"}
                          </p>
                          <span className="text-yellow-600 font-semibold">
                            ⭐ {review.rating} / 5
                          </span>
                        </div>
                        {review.comment && (
                          <p className="text-sm text-gray-700 mt-2 whitespace-pre-line">
                            {review.comment}
                          </p>
                        )}
                        <p className="text-xs text-gray-500 mt-2">
                          {new Date(review.createdAt).toLocaleDateString()}
                        </p>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </>
          )}
        </div>
      </main>
    </Protected>
  );
}
