import React from "react";
import { Listing } from "@/src/models/Listing";

type OrderModalProps = {
  isOpen: boolean;
  listing: Listing;
  orderQuantity: number;
  onClose: () => void;
  onSubmit: (e: React.FormEvent) => void;
  selectedSize: string | null;
  setOrderQuantity: (value: number) => void;
  setSelectedSize: (value: string | null) => void;
  deliveryMode: "retrait" | "livraison";
  setDeliveryMode: (value: "retrait" | "livraison") => void;
  deliveryAddress: string;
  setDeliveryAddress: (value: string) => void;
  deliveryPhone: string;
  setDeliveryPhone: (value: string) => void;
  hasProfileContact: boolean;
  useProfileContact: boolean;
  toggleProfileContact: (checked: boolean) => void;
};

const OrderModal: React.FC<OrderModalProps> = ({
  isOpen,
  listing,
  orderQuantity,
  onClose,
  onSubmit,
  selectedSize,
  setOrderQuantity,
  setSelectedSize,
  deliveryMode,
  setDeliveryMode,
  deliveryAddress,
  setDeliveryAddress,
  deliveryPhone,
  setDeliveryPhone,
  hasProfileContact,
  useProfileContact,
  toggleProfileContact,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-xl border border-gray-200">
        <div className="flex items-center justify-between px-6 py-4 border-b">
          <h3 className="text-lg font-semibold">Commander</h3>
          <button
            type="button"
            onClick={onClose}
            className="text-2xl leading-none hover:text-red-600"
            aria-label="Fermer la commande"
          >
            ×
          </button>
        </div>

        <form onSubmit={onSubmit} className="p-6 space-y-5">
          <div className="space-y-2">
            <label className="block text-sm font-medium">Quantité</label>
            <input
              type="number"
              min={1}
              value={orderQuantity}
              onChange={(e) =>
                setOrderQuantity(Math.max(1, Number(e.target.value) || 1))
              }
              className="w-full rounded-lg border border-gray-300 px-3 py-2"
            />
          </div>

          {listing.sizes?.length ? (
            <div className="space-y-2">
              <p className="text-sm font-medium">Taille</p>
              <div className="flex flex-wrap gap-2">
                {listing.sizes.map((size) => (
                  <label
                    key={size}
                    className={`px-4 py-2 rounded-lg border cursor-pointer transition ${
                      selectedSize === size
                        ? "bg-blue-50 border-blue-500 text-blue-700"
                        : "bg-white border-gray-300"
                    }`}
                  >
                    <input
                      type="radio"
                      name="size"
                      value={size}
                      checked={selectedSize === size}
                      onChange={() => setSelectedSize(size)}
                      className="hidden"
                    />
                    {size}
                  </label>
                ))}
              </div>
            </div>
          ) : null}

          <div className="space-y-2">
            <p className="text-sm font-medium">Mode de livraison</p>
            <div className="flex gap-4">
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  name="deliveryMode"
                  value="retrait"
                  checked={deliveryMode === "retrait"}
                  onChange={() => setDeliveryMode("retrait")}
                />
                <span>Retrait</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  name="deliveryMode"
                  value="livraison"
                  checked={deliveryMode === "livraison"}
                  onChange={() => setDeliveryMode("livraison")}
                />
                <span>Livraison</span>
              </label>
            </div>
          </div>

          {deliveryMode === "livraison" && (
            <div className="space-y-4 border rounded-xl p-4 bg-gray-50 border-gray-200">
              <div className="space-y-1">
                <label className="block text-sm font-medium">Adresse</label>
                <input
                  type="text"
                  value={deliveryAddress}
                  onChange={(e) => setDeliveryAddress(e.target.value)}
                  placeholder="Saisissez votre adresse"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2"
                />
              </div>
              <div className="space-y-1">
                <label className="block text-sm font-medium">Téléphone</label>
                <input
                  type="tel"
                  value={deliveryPhone}
                  onChange={(e) => setDeliveryPhone(e.target.value)}
                  placeholder="Saisissez votre numéro"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2"
                />
              </div>

              {hasProfileContact && (
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={useProfileContact}
                    onChange={(e) => toggleProfileContact(e.target.checked)}
                  />
                  <span>Utiliser l'adresse et le téléphone par défaut du profil</span>
                </label>
              )}
            </div>
          )}

          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-100"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="px-5 py-2 rounded-lg bg-blue-600 text-white font-medium hover:bg-blue-700"
            >
              Valider
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default OrderModal;
