"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

import AppHeader from "@/src/components/AppHeader";
import ImageUploader from "@/src/components/ImageUploader";
import { useAuth } from "@/src/context/AuthContext";
import { ApiService } from "@/src/services/api";
import { uploadImage } from "@/src/services/uploadService";

type Category = {
  id: number;
  name: string;
  children?: Category[];
};

const COLOR_OPTIONS: { name: string; hex: string }[] = [
  { name: "Noir", hex: "#000000" },
  { name: "Blanc", hex: "#FFFFFF" },
  { name: "Gris", hex: "#808080" },
  { name: "Rouge", hex: "#FF0000" },
  { name: "Bordeaux", hex: "#800020" },
  { name: "Rose", hex: "#FFC0CB" },
  { name: "Orange", hex: "#FFA500" },
  { name: "Jaune", hex: "#FFFF00" },
  { name: "Vert", hex: "#008000" },
  { name: "Bleu", hex: "#0000FF" },
  { name: "Bleu ciel", hex: "#87CEEB" },
  { name: "Turquoise", hex: "#40E0D0" },
  { name: "Violet", hex: "#800080" },
  { name: "Marron", hex: "#8B4513" },
];

export default function NewListingPage() {
  const router = useRouter();
  const { user } = useAuth();

  const isSeller = useMemo(() => Boolean(user && user.role === "seller"), [user]);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [city, setCity] = useState("");
  const [condition, setCondition] = useState("neuf");
  const [deliveryAvailable, setDeliveryAvailable] = useState(false);
  const [categoryId, setCategoryId] = useState<number | null>(null);
  const [sizes, setSizes] = useState<string[]>([]);
  const [colors, setColors] = useState<string[]>([]);
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  const [categories, setCategories] = useState<Category[]>([]);
  const [categoryError, setCategoryError] = useState<string | null>(null);
  const [categoryLoading, setCategoryLoading] = useState(false);

  const [sizeOptions, setSizeOptions] = useState<string[]>([]);
  const [sizesLoading, setSizesLoading] = useState(false);
  const [sizesError, setSizesError] = useState<string | null>(null);

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  useEffect(() => {
    if (!user || !isSeller) return;

    setCategoryLoading(true);
    ApiService.fetchCategoryTree()
      .then((data) => {
        setCategories(data);
        setCategoryError(null);
      })
      .catch(() => setCategoryError("Impossible de charger les catégories."))
      .finally(() => setCategoryLoading(false));
  }, [user, isSeller]);

  useEffect(() => {
    if (!categoryId) {
      setSizeOptions([]);
      setSizes([]);
      return;
    }

    setSizesLoading(true);
    setSizesError(null);

    ApiService.fetchSizesForCategory(categoryId)
      .then((list) => {
        setSizeOptions(list);
        setSizes((prev) => prev.filter((size) => list.includes(size)));
      })
      .catch(() => setSizesError("Impossible de charger les tailles."))
      .finally(() => setSizesLoading(false));
  }, [categoryId]);

  const flatCategories = useMemo(() => {
    const res: Category[] = [];
    const walk = (nodes: Category[], prefix = "") => {
      for (const c of nodes) {
        res.push({ ...c, name: prefix ? `${prefix} › ${c.name}` : c.name });
        if (c.children?.length) {
          walk(c.children, prefix ? `${prefix} › ${c.name}` : c.name);
        }
      }
    };
    walk(categories);
    return res;
  }, [categories]);

  const toggleSize = (size: string) => {
    setSizes((prev) =>
      prev.includes(size) ? prev.filter((s) => s !== size) : [...prev, size]
    );
  };

  const toggleColor = (color: string) => {
    setColors((prev) =>
      prev.includes(color) ? prev.filter((c) => c !== color) : [...prev, color]
    );
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!user || !isSeller) return;

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    const parsedPrice = Number(price);
    if (Number.isNaN(parsedPrice) || parsedPrice <= 0) {
      setError("Veuillez saisir un prix valide.");
      setSubmitting(false);
      return;
    }

    const ok = await ApiService.createListing({
      title: title.trim(),
      description: description.trim(),
      price: parsedPrice,
      sizes,
      colors,
      condition: condition.trim(),
      categoryId: categoryId ?? undefined,
      city: city.trim() || undefined,
      images: imageUrls,
      deliveryAvailable,
    });

    if (!ok) {
      setError("La création de l'annonce a échoué.");
      setSubmitting(false);
      return;
    }

    setSuccess("Annonce créée avec succès.");
    setSubmitting(false);
    router.push("/dashboard/listings");
  };

  const handleImageUpload = async (file: File) => {
    if (imageUrls.length >= 10) {
      setUploadError("Vous pouvez ajouter jusqu'à 10 images maximum.");
      return;
    }

    setUploading(true);
    setUploadError(null);
    try {
      const url = await uploadImage(file, "listing");
      setImageUrls((prev) => {
        if (prev.length >= 10) {
          setUploadError("Vous pouvez ajouter jusqu'à 10 images maximum.");
          return prev;
        }

        const updated = [...prev, url];
        if (updated.length >= 10) {
          setUploadError("Limite de 10 images atteinte.");
        }
        return updated;
      });
    } catch (e) {
      const message =
        e instanceof Error
          ? e.message
          : "Impossible de téléverser l'image.";
      setUploadError(message);
    } finally {
      setUploading(false);
    }
  };

  const handleRemoveImage = (url: string) => {
    setImageUrls((prev) => prev.filter((img) => img !== url));
  };

  return (
    <main className="bg-gray-50 min-h-screen">
      <AppHeader />

      <div className="max-w-4xl mx-auto px-4 py-8">
        {!user && (
          <div className="bg-white rounded-xl shadow-sm border border-neutral-200 p-6 space-y-3">
            <h1 className="text-2xl font-semibold">Espace réservé</h1>
            <p>Connectez-vous avec un compte vendeur pour créer une annonce.</p>
            <div className="flex gap-3">
              <Link
                href="/auth/login"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg"
              >
                Connexion
              </Link>
              <Link
                href="/auth/register"
                className="px-4 py-2 border border-neutral-300 rounded-lg"
              >
                Créer un compte
              </Link>
            </div>
          </div>
        )}

        {user && !isSeller && (
          <div className="bg-white rounded-xl shadow-sm border border-neutral-200 p-6 space-y-3">
            <h1 className="text-2xl font-semibold">Accès réservé</h1>
            <p>Seuls les vendeurs peuvent publier une annonce.</p>
              <Link href="/" className="text-blue-600 underline">
                Retour à l&apos;accueil
              </Link>
          </div>
        )}

        {user && isSeller && (
          <div className="bg-white rounded-xl shadow-sm border border-neutral-200 p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <p className="text-sm text-neutral-500">Nouvelle annonce</p>
                <h1 className="text-2xl font-semibold">Ajouter une annonce</h1>
              </div>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">
                    Titre
                  </label>
                  <input
                    className="w-full border border-neutral-200 rounded-lg px-3 py-2"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="Titre de votre annonce"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">
                    Ville
                  </label>
                  <input
                    className="w-full border border-neutral-200 rounded-lg px-3 py-2"
                    value={city}
                    onChange={(e) => setCity(e.target.value)}
                    placeholder="Tunis, Sfax..."
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">
                    Prix (TND)
                  </label>
                  <input
                    className="w-full border border-neutral-200 rounded-lg px-3 py-2"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    type="number"
                    min={0}
                    step="0.01"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">
                    Condition
                  </label>
                  <select
                    className="w-full border border-neutral-200 rounded-lg px-3 py-2 bg-white"
                    value={condition}
                    onChange={(e) => setCondition(e.target.value)}
                  >
                    <option value="neuf">Neuf</option>
                    <option value="comme neuf">Comme neuf</option>
                    <option value="bon etat">Bon état</option>
                    <option value="usage">Usagé</option>
                  </select>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-700">Description</label>
                <textarea
                  className="w-full border border-neutral-200 rounded-lg px-3 py-2 min-h-[120px]"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Décrivez votre produit"
                  required
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">Catégorie</label>
                  <select
                    className="w-full border border-neutral-200 rounded-lg px-3 py-2 bg-white"
                    value={categoryId ?? ""}
                    onChange={(e) =>
                      setCategoryId(e.target.value ? Number(e.target.value) : null)
                    }
                  >
                    <option value="">Sélectionner une catégorie</option>
                    {flatCategories.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.name}
                      </option>
                    ))}
                  </select>
                  {categoryLoading && (
                    <p className="text-xs text-neutral-500">Chargement des catégories...</p>
                  )}
                  {categoryError && (
                    <p className="text-xs text-red-600">{categoryError}</p>
                  )}
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">Livraison</label>
                  <div className="flex items-center gap-2">
                    <input
                      id="delivery"
                      type="checkbox"
                      checked={deliveryAvailable}
                      onChange={(e) => setDeliveryAvailable(e.target.checked)}
                    />
                    <label htmlFor="delivery" className="text-sm text-neutral-700">
                      Livraison disponible
                    </label>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-3">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-neutral-700">Tailles</label>
                    {sizesLoading && (
                      <p className="text-xs text-neutral-500">Chargement des tailles...</p>
                    )}
                    {sizesError && (
                      <p className="text-xs text-red-600">{sizesError}</p>
                    )}
                    {sizeOptions.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {sizeOptions.map((size) => (
                          <button
                            key={size}
                            type="button"
                            onClick={() => toggleSize(size)}
                            className={`px-3 py-1 rounded-full border text-sm ${
                              sizes.includes(size)
                                ? "bg-blue-600 text-white border-blue-600"
                                : "border-neutral-200"
                            }`}
                          >
                            {size}
                          </button>
                        ))}
                      </div>
                    ) : (
                      <p className="text-xs text-neutral-500">
                        Sélectionnez une catégorie pour voir les tailles disponibles.
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium text-neutral-700">Images</label>
                    <div className="space-y-2">
                      <ImageUploader onUpload={handleImageUpload} loading={uploading} />
                      <p className="text-xs text-neutral-500">
                        Jusqu&apos;à 10 images. Utilisez le même téléversement que pour la photo de
                        profil.
                      </p>
                      {uploadError && (
                        <p className="text-xs text-red-600">{uploadError}</p>
                      )}
                    </div>
                    {imageUrls.length > 0 && (
                      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                        {imageUrls.map((url) => (
                          <div
                            key={url}
                            className="relative border rounded-lg overflow-hidden bg-neutral-100"
                          >
                            <img
                              src={url}
                              alt="Aperçu de l'annonce"
                              className="w-full h-32 object-cover"
                            />
                            <button
                              type="button"
                              onClick={() => handleRemoveImage(url)}
                              className="absolute top-2 right-2 bg-black/60 text-white text-xs px-2 py-1 rounded"
                            >
                              Retirer
                            </button>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-neutral-700">Couleurs</label>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                    {COLOR_OPTIONS.map((color) => (
                      <button
                        key={color.name}
                        type="button"
                        onClick={() => toggleColor(color.name)}
                        className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm ${
                          colors.includes(color.name)
                            ? "border-blue-600 bg-blue-50"
                            : "border-neutral-200"
                        }`}
                      >
                        <span
                          className="w-4 h-4 rounded-full border"
                          style={{ backgroundColor: color.hex }}
                        />
                        {color.name}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {error && <p className="text-red-600 text-sm">{error}</p>}
              {success && <p className="text-green-600 text-sm">{success}</p>}

              <div className="flex items-center gap-3">
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-blue-600 text-white rounded-full font-semibold disabled:opacity-60"
                >
                  {submitting ? "Publication..." : "Publier l'annonce"}
                </button>
                <button
                  type="button"
                  onClick={() => router.back()}
                  className="px-5 py-2 border border-neutral-300 rounded-full"
                >
                  Annuler
                </button>
              </div>
            </form>
          </div>
        )}
      </div>
    </main>
  );
}