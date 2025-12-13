"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ApiService } from "@/src/services/api";
import { Listing } from "@/src/models/Listing";
import { useAuth } from "@/src/context/AuthContext";
import AppHeader from "@/src/components/AppHeader";
import ListingsGrid from "@/src/components/ListingsGrid";
import OrderModal from "@/src/components/OrderModal";
import { FaHeart } from "react-icons/fa";
import VendorCard from "@/src/components/VendorCard";
import NewListingModal from "@/src/components/NewListingModal";
import Button from "@/src/components/Button";
export default function ListingDetailPage() {
  const params = useParams<{ id: string }>();
  const { user } = useAuth();
  const router = useRouter();

  const [listing, setListing] = useState<Listing | null>(null);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [sellerListings, setSellerListings] = useState<Listing[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isFavoriteListing, setIsFavoriteListing] = useState(false);
  const [isFavoriteSeller, setIsFavoriteSeller] = useState(false);
  // Popup state
  const [isOpen, setIsOpen] = useState(false);
  const [popupImage, setPopupImage] = useState<string | null>(null);
  const [isOrderModalOpen, setIsOrderModalOpen] = useState(false);
  const [orderQuantity, setOrderQuantity] = useState(1);
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [deliveryMode, setDeliveryMode] = useState<"retrait" | "livraison">(
    "retrait"
  );
  const [deliveryAddress, setDeliveryAddress] = useState("");
  const [deliveryPhone, setDeliveryPhone] = useState("");
  const [useProfileContact, setUseProfileContact] = useState(false);
  const [isOrdering, setIsOrdering] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
const [showFullDescription, setShowFullDescription] = useState(false);

  const isClient = user?.role === "client";
  const isSeller = user?.role === "seller";

  const loadListing = async () => {
    const id = Number(params?.id);
    if (!id) return;

    try {
      setError(null);
      const data = await ApiService.fetchListingDetail(id);
      setListing(data);
      setSelectedImage(data.imageUrls?.[0] ?? data.imageUrl ?? null);

      if (data.sellerId) {
        const res = await ApiService.fetchUserListings(data.sellerId);
        setSellerListings(res.filter((x) => x.id !== id));
      }
    } catch (e: any) {
      setError(e.message);
    }
  };

  useEffect(() => {
    void loadListing();
  }, [params?.id]);

  useEffect(() => {
    if (listing?.sizes?.length) {
      setSelectedSize(listing.sizes[0]);
    }
  }, [listing?.sizes]);

  useEffect(() => {
    const loadFavorites = async () => {
      if (!user || !listing) {
        setIsFavoriteListing(false);
        setIsFavoriteSeller(false);
        return;
      }

      try {
        const favorites = await ApiService.fetchFavorites();
        setIsFavoriteListing(
          favorites.listings.some((fav) => fav.id === listing.id)
        );
        setIsFavoriteSeller(
          favorites.sellers.some((fav) => fav.id === listing.sellerId)
        );
      } catch (err) {
        console.error("Impossible de charger les favoris", err);
      }
    };

    void loadFavorites();
  }, [user?.id, listing?.id, listing?.userId]);

  const hasProfileContact = Boolean(user?.address || user?.phone);

  const openOrderModal = () => {
    if (!user) {
      router.push("/auth/login");
      return;
    }

    if (!isClient) {
      setActionError("Seuls les clients peuvent passer une commande.");
      return;
    }

    setOrderQuantity(1);
    setSelectedSize(listing?.sizes?.[0] ?? null);
    setDeliveryMode("retrait");
    setUseProfileContact(false);
    setDeliveryAddress(user?.address ?? "");
    setDeliveryPhone(user?.phone ?? "");
    setActionError(null);
    setIsOrderModalOpen(true);
  };

  const toggleProfileContact = (checked: boolean) => {
    setUseProfileContact(checked);
    if (checked) {
      setDeliveryAddress(user?.address ?? "");
      setDeliveryPhone(user?.phone ?? "");
    }
  };

  const toggleFavoriteListing = async () => {
    if (!user) {
      router.push("/auth/login");
      return;
    }

    if (!listing) return;

    setActionError(null);
    const nextState = !isFavoriteListing;
    setIsFavoriteListing(nextState);

    try {
      const ok = nextState
        ? await ApiService.addFavoriteListing(listing.id)
        : await ApiService.removeFavoriteListing(listing.id);

      if (!ok) {
        throw new Error("Impossible de mettre à jour les favoris.");
      }
    } catch (err: any) {
      setIsFavoriteListing(!nextState);
      setActionError(err?.message ?? "Impossible de mettre à jour les favoris.");
    }
  };

  const toggleFavoriteSeller = async () => {
    if (!user) {
      router.push("/auth/login");
      return;
    }

    if (!listing?.sellerId) return;

    setActionError(null);
    const nextState = !isFavoriteSeller;
    setIsFavoriteSeller(nextState);

    try {
      const ok = nextState
        ? await ApiService.addFavoriteSeller(listing.sellerId)
        : await ApiService.removeFavoriteSeller(listing.sellerId);

      if (!ok) {
        throw new Error("Impossible de mettre à jour les favoris vendeur.");
      }
    } catch (err: any) {
      setIsFavoriteSeller(!nextState);
      setActionError(
        err?.message ?? "Impossible de mettre à jour les favoris vendeur."
      );
    }
  };
  const handleSubmitOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!listing) return;

    if (
      deliveryMode === "livraison" &&
      (!deliveryAddress.trim() || !deliveryPhone.trim())
    ) {
      setActionError(
        "Merci de renseigner l'adresse et le téléphone pour la livraison."
      );
      return;
    }

    setActionError(null);
    setIsOrdering(true);

    try {
      await ApiService.createOrder({
        listingId: listing.id,
        quantity: orderQuantity,
        receptionMode: deliveryMode,
        size: selectedSize ?? undefined,
        shippingAddress: deliveryMode === "livraison" ? deliveryAddress : undefined,
        phone: deliveryMode === "livraison" ? deliveryPhone : undefined,
      });

      setIsOrderModalOpen(false);
      router.push("/orders");
    } catch (err: any) {
      setActionError(err.message ?? "Impossible de passer la commande.");
    } finally {
      setIsOrdering(false);
    }
  };

  const handleDeleteListing = async () => {
    if (!listing) return;
    const confirmed = window.confirm(
      "Voulez-vous vraiment supprimer cette annonce ?"
    );
    if (!confirmed) return;

    setIsDeleting(true);
    setActionError(null);
    try {
      const ok = await ApiService.deleteListing(listing.id);
      if (ok) {
        router.push("/dashboard/listings");
      } else {
        setActionError("Suppression impossible pour le moment.");
      }
    } catch (e: any) {
      setActionError(e.message ?? "Suppression impossible pour le moment.");
    } finally {
      setIsDeleting(false);
    }
  };

  const isOwner = Boolean(user?.id && listing?.sellerId === user.id);

  if (error)
    return <div className="max-w-6xl mx-auto px-4 py-8 text-red-600">{error}</div>;

  if (!listing)
    return <div className="max-w-6xl mx-auto px-4 py-8">Chargement...</div>;

  return (
    <main className="bg-gray-50 min-h-screen">
      <AppHeader />


	  <div className="max-w-6xl mx-auto px-4 pt-8 pb-20 scale-[1] origin-top transition-transform">


        {/* ---------------------------------------------------
            GRID: LEFT (image container) + RIGHT (details container)
        --------------------------------------------------- */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">

          {/* ---------------------- LEFT BIG CONTAINER ---------------------- */}
<div className="bg-gray-50 p-4 rounded-2xl shadow-md hover:shadow-lg transition border border-gray-200 space-y-4 self-start min-h-[650px]">

            {/* MAIN IMAGE */}
           <div
  className="rounded-xl overflow-hidden bg-transparent cursor-zoom-in border border-gray-300"
  onClick={() => {
    setPopupImage(selectedImage);
    setIsOpen(true);
  }}
>
  <img
    src={selectedImage || "/placeholder-listing.svg"}
    alt={listing.title}
    className="w-full h-[520px] object-contain bg-transparent"
  />
</div>

{/* MINIATURES */}
<div className="flex gap-4 mt-2">
  {listing.imageUrls?.map((img) => (
    <button
      key={img}
      onClick={() => setSelectedImage(img)}
      className={`w-24 h-24 border-2 rounded-xl overflow-hidden transition ${
        selectedImage === img
          ? "border-blue-600"
          : "border-neutral-300 hover:border-neutral-400"
      }`}
    >
      <img
        src={img}
        alt=""
        className="w-full h-full object-cover"
      />
    </button>
  ))}
</div>


          </div>

          {/* ---------------------- RIGHT BIG CONTAINER ---------------------- */}
<div className="bg-gray-50 p-6 rounded-2xl shadow-md hover:shadow-lg transition border border-gray-200 relative space-y-4 max-w-[420px] w-full">

            {/* ❤️ Favorite Button for ARTICLE */}
            <button
              onClick={toggleFavoriteListing}
              className="absolute top-4 right-4 transition transform hover:scale-110"
              aria-label="Favori article"
            >
              <FaHeart
                size={26}
                className={`transition ${
                  isFavoriteListing ? "text-red-600 scale-110" : "text-gray-200"
                }`}
              />
            </button>


            <h1 className="text-2xl font-semibold">{listing.title}</h1>
            <p className="text-blue-600 font-semibold text-2xl">
              {listing.price} DT
            </p>

            {/* PRODUCT INFO */}
<div className="bg-gray-60 rounded-xl p-5  border border-gray-200 space-y-2 text-sm">
              <p className="flex justify-between"><span>Référence</span><span>{listing.referenceCode ?? "—"}</span></p>
              <p className="flex justify-between"><span>État</span><span>{listing.condition ?? "—"}</span></p>
              <p className="flex justify-between"><span>Tailles</span><span>{listing.sizes?.join(" / ") || "—"}</span></p>
              <p className="flex justify-between"><span>Couleurs</span><span>{listing.colors?.join(", ") || "—"}</span></p>
              <p className="flex justify-between"><span>Genre</span><span>{listing.gender ?? "—"}</span></p>
              <p className="flex justify-between"><span>Ville</span><span>{listing.city ?? "—"}</span></p>
            </div>

            {/* DESCRIPTION */}
 {/* DESCRIPTION */}
<div>
  <h3 className="font-semibold mb-1">Description</h3>

  <p
    className={`text-neutral-700 whitespace-pre-line break-words transition-all ${
      showFullDescription ? "" : "line-clamp-2"
    }`}
  >
    {listing.description}
  </p>

  {/* VOIR PLUS / MOINS */}
  {listing.description && (
    <button
      onClick={() => setShowFullDescription((v) => !v)}
      className="text-blue-600 font-semibold mt-1 hover:underline"
    >
      {showFullDescription ? "Voir moins" : "Voir plus"}
    </button>
  )}
</div>



            {actionError && (
              <p className="text-red-600 text-sm">{actionError}</p>
            )}
       {/* SELLER BOX */}


            {/* BUTTONS */}
            {isOwner ? (
              listing.isDeleted ? (
                <button
                  onClick={() => setIsEditModalOpen(true)}
                  className="px-5 py-3 bg-blue-600 text-white font-medium rounded-lg w-full"
                >
                  Republier l'annonce
                </button>
              ) : (
                <div className="flex flex-col sm:flex-row gap-3">
                  <button
                    onClick={() => setIsEditModalOpen(true)}
                    className="px-5 py-3 bg-blue-600 text-white font-medium rounded-lg w-full"
                  >
                    Modifier
                  </button>
                  <button
                    onClick={handleDeleteListing}
                    disabled={isDeleting}
                    className="px-5 py-3 bg-red-600 text-white font-medium rounded-lg w-full disabled:opacity-60"
                  >
                    {isDeleting ? "Suppression..." : "Supprimer"}
                  </button>
                </div>
              )
            ) : (
<div className="flex justify-center mt-5">
  <Button
    size="md"
    variant="primary"
    onClick={openOrderModal}
    disabled={Boolean(user && !isClient)}
    className="w-[240px] py-3"
    style={{ opacity: user && !isClient ? 0.5 : 1 }}
  >
    {isSeller ? "Seuls les clients peuvent commander" : "Commander"}
  </Button>
  
</div>

            )}
<div className="relative  mt-7">
  {/* ❤️ Favorite Seller Button */}
  <button
    onClick={toggleFavoriteSeller}
    className="absolute top-2 right-2 hover:scale-110 transition"
    aria-label="Favori vendeur"
  >
    <FaHeart
      size={22}
      className={isFavoriteSeller ? "text-red-500" : "text-gray-300"}
    />
  </button>

  {/* Seller Card */}
  <VendorCard
    sellerId={listing.sellerId}
    avatarSize={50}
    padding="p-4"
    showEditButton={false}
  />
</div>
     

          </div>

        </div>

        {/* OTHER SELLER ITEMS */}
        {sellerListings.length > 0 && (
          <div className="mt-16">
            <h2 className="text-xl font-semibold mb-4">
              Autres articles du vendeur
            </h2>

<div className="w-full flex justify-center">
  <div className="scale-[1] origin-top">
<ListingsGrid
  listings={sellerListings}
  columns={{ base: 2, sm: 2, md: 4, lg: 4 }}
  rows={{ base: 1, md: 1, lg: 1 }}
/>
  </div>
</div>

          </div>
        )}
      </div>

      <OrderModal
        isOpen={isOrderModalOpen}
        listing={listing}
        orderQuantity={orderQuantity}
        onClose={() => setIsOrderModalOpen(false)}
        onSubmit={handleSubmitOrder}
        selectedSize={selectedSize}
        setOrderQuantity={setOrderQuantity}
        setSelectedSize={setSelectedSize}
        deliveryMode={deliveryMode}
        setDeliveryMode={setDeliveryMode}
        deliveryAddress={deliveryAddress}
        setDeliveryAddress={setDeliveryAddress}
        deliveryPhone={deliveryPhone}
        setDeliveryPhone={setDeliveryPhone}
        hasProfileContact={hasProfileContact}
        useProfileContact={useProfileContact}
        toggleProfileContact={toggleProfileContact}
        isSubmitting={isOrdering}
      />

      {/* POPUP IMAGE FULLSCREEN */}
      {isOpen && popupImage && (
        <div
          className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center"
          onClick={() => setIsOpen(false)}
        >
          <div
            className="relative max-w-5xl max-h-[90vh] p-4"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setIsOpen(false)}
              className="absolute -top-10 right-0 text-white text-3xl font-bold"
            >
              ×
            </button>

            <img
              src={popupImage}
              alt="Preview"
              className="max-w-full max-h-[90vh] object-contain rounded-xl"
            />
          </div>
        </div>
      )}

      <NewListingModal
        open={isEditModalOpen}
        listing={listing}
        onClose={() => setIsEditModalOpen(false)}
        onSuccess={() => {
          void loadListing();
          setIsEditModalOpen(false);
        }}
      />
    </main>
  );
}
