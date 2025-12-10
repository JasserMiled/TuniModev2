"use client";

import { useEffect, useState } from "react";
import { ApiService } from "@/src/services/api";

export type QuickFiltersSelection = {
  city?: string | null;
  minPrice?: number | null;
  maxPrice?: number | null;
  categoryId?: number | null;
  sizes: string[];
  colors: string[];
  deliveryAvailable?: boolean | null;
};

type Category = {
  id: number;
  name: string;
  children?: Category[];
};

type QuickFiltersDialogProps = {
  open: boolean;
  onClose: () => void;

  initialSelection: QuickFiltersSelection;

  onApply: (selection: QuickFiltersSelection) => void;
  onReset: () => void;
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

export default function QuickFiltersDialog({
  open,
  onClose,
  initialSelection,
  onApply,
  onReset,
}: QuickFiltersDialogProps) {
  const [city, setCity] = useState(initialSelection.city ?? "");
  const [minPrice, setMinPrice] = useState<string>(
    initialSelection.minPrice?.toString() ?? ""
  );
  const [maxPrice, setMaxPrice] = useState<string>(
    initialSelection.maxPrice?.toString() ?? ""
  );
  const [categoryId, setCategoryId] = useState<number | null>(
    initialSelection.categoryId ?? null
  );
  const [sizes, setSizes] = useState<string[]>(initialSelection.sizes ?? []);
  const [colors, setColors] = useState<string[]>(initialSelection.colors ?? []);
  const [delivery, setDelivery] = useState<boolean | null>(
    initialSelection.deliveryAvailable ?? null
  );

  const [categories, setCategories] = useState<Category[]>([]);
  const [catLoading, setCatLoading] = useState(false);
  const [catError, setCatError] = useState<string | null>(null);

  const [sizeOptions, setSizeOptions] = useState<string[]>([]);
  const [sizesLoading, setSizesLoading] = useState(false);
  const [sizesError, setSizesError] = useState<string | null>(null);

  // Charger les catégories au premier open
  useEffect(() => {
    if (!open) return;
    if (categories.length > 0) return;

    setCatLoading(true);
    ApiService.fetchCategoriesTree?.()
      .then((data: Category[]) => {
        setCategories(data);
        setCatError(null);
      })
      .catch((e: any) => setCatError(e.message ?? "Erreur de chargement"))
      .finally(() => setCatLoading(false));
  }, [open, categories.length]);

  // Charger les tailles quand la catégorie change
  useEffect(() => {
    if (!open) return;
    if (!categoryId) {
      setSizeOptions([]);
      setSizes([]);
      return;
    }

    setSizesLoading(true);
    setSizesError(null);

    ApiService.fetchSizesForCategory(categoryId)
      .then((list: string[]) => {
        setSizeOptions(list);
        // garder uniquement les tailles encore valides
        setSizes((prev) => prev.filter((s) => list.includes(s)));
      })
      .catch(() =>
        setSizesError("Impossible de charger les tailles pour cette catégorie.")
      )
      .finally(() => setSizesLoading(false));
  }, [open, categoryId]);

  useEffect(() => {
    if (open) {
      // reset à chaque ouverture selon initialSelection
      setCity(initialSelection.city ?? "");
      setMinPrice(initialSelection.minPrice?.toString() ?? "");
      setMaxPrice(initialSelection.maxPrice?.toString() ?? "");
      setCategoryId(initialSelection.categoryId ?? null);
      setSizes(initialSelection.sizes ?? []);
      setColors(initialSelection.colors ?? []);
      setDelivery(initialSelection.deliveryAvailable ?? null);
    }
  }, [open, initialSelection]);

  if (!open) return null;

  const handleApply = () => {
    onApply({
      city: city.trim() || null,
      minPrice: minPrice.trim() ? Number(minPrice) : null,
      maxPrice: maxPrice.trim() ? Number(maxPrice) : null,
      categoryId,
      sizes,
      colors,
      deliveryAvailable: delivery,
    });
    onClose();
  };

  const handleReset = () => {
    onReset();
    onClose();
  };

  const toggleSize = (size: string) => {
    setSizes((prev) =>
      prev.includes(size) ? prev.filter((s) => s !== size) : [...prev, size]
    );
  };

  const toggleColor = (colorName: string) => {
    setColors((prev) =>
      prev.includes(colorName)
        ? prev.filter((c) => c !== colorName)
        : [...prev, colorName]
    );
  };

  const flatCategories = (tree: Category[]): Category[] => {
    const res: Category[] = [];
    const walk = (nodes: Category[], prefix = "") => {
      for (const c of nodes) {
        res.push({ ...c, name: prefix ? `${prefix} › ${c.name}` : c.name });
        if (c.children && c.children.length > 0) {
          walk(c.children, `${c.name}`);
        }
      }
    };
    walk(tree);
    return res;
  };

  const flatCats = flatCategories(categories);

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40">
      <div className="w-full max-w-xl bg-[#F7F7FB] rounded-xl shadow-lg flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-5 py-3 border-b border-neutral-200 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Filtres rapides</h2>
          <button
            onClick={onClose}
            className="text-neutral-500 hover:text-neutral-800 text-xl"
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div className="px-5 py-4 overflow-y-auto space-y-5">
          {/* VILLE */}
          <section>
            <p className="text-sm font-semibold mb-1">Ville</p>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-500">
                📍
              </span>
              <input
                className="w-full pl-9 pr-3 py-2 rounded-md border border-neutral-300 bg-white text-sm"
                placeholder="Ex : Tunis, Sousse, Bizerte..."
                value={city}
                onChange={(e) => setCity(e.target.value)}
              />
            </div>
          </section>

          {/* CATEGORIE */}
          <section>
            <p className="text-sm font-semibold mb-1">Catégorie</p>
            {catLoading ? (
              <p className="text-sm text-neutral-500">Chargement...</p>
            ) : catError ? (
              <p className="text-sm text-red-600">{catError}</p>
            ) : (
              <select
                className="w-full border border-neutral-300 rounded-md px-3 py-2 text-sm bg-white"
                value={categoryId ?? ""}
                onChange={(e) =>
                  setCategoryId(
                    e.target.value ? Number(e.target.value) : null
                  )
                }
              >
                <option value="">Toutes les catégories</option>
                {flatCats.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
            )}
          </section>

          {/* TAILLES / COULEURS / LIVRAISON */}
          <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Tailles */}
            <div>
              <p className="text-sm font-semibold mb-1">Tailles</p>
              {!categoryId ? (
                <p className="text-xs text-neutral-500">
                  Sélectionnez une catégorie pour afficher les tailles.
                </p>
              ) : sizesLoading ? (
                <p className="text-xs text-neutral-500">
                  Chargement des tailles...
                </p>
              ) : sizesError ? (
                <p className="text-xs text-red-600">{sizesError}</p>
              ) : sizeOptions.length === 0 ? (
                <p className="text-xs text-neutral-500">
                  Aucune taille pour cette catégorie.
                </p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {sizeOptions.map((s) => (
                    <button
                      key={s}
                      type="button"
                      onClick={() => toggleSize(s)}
                      className={`px-2 py-1 rounded-full border text-xs ${
                        sizes.includes(s)
                          ? "bg-blue-600 text-white border-blue-600"
                          : "bg-white text-neutral-700 border-neutral-300"
                      }`}
                    >
                      {s}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Couleurs */}
            <div>
              <p className="text-sm font-semibold mb-1">Couleurs</p>
              <div className="flex flex-wrap gap-2">
                {COLOR_OPTIONS.map((c) => (
                  <button
                    key={c.name}
                    type="button"
                    onClick={() => toggleColor(c.name)}
                    className={`flex items-center gap-1 px-2 py-1 rounded-full border text-xs ${
                      colors.includes(c.name)
                        ? "border-blue-600 bg-blue-50"
                        : "border-neutral-300 bg-white"
                    }`}
                  >
                    <span
                      style={{ backgroundColor: c.hex }}
                      className="w-3 h-3 rounded-full border border-neutral-300"
                    />
                    <span>{c.name}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Livraison */}
            <div>
              <p className="text-sm font-semibold mb-1">Livraison</p>
              <select
                className="w-full border border-neutral-300 rounded-md px-3 py-2 text-sm bg-white"
                value={
                  delivery === null
                    ? ""
                    : delivery === true
                    ? "true"
                    : "false"
                }
                onChange={(e) => {
                  const v = e.target.value;
                  if (!v) setDelivery(null);
                  else setDelivery(v === "true");
                }}
              >
                <option value="">Tous</option>
                <option value="true">Livraison</option>
                <option value="false">Retrait</option>
              </select>
            </div>
          </section>

          {/* Budget */}
          <section>
            <p className="text-sm font-semibold mb-1">Budget</p>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs text-neutral-500 mb-1">
                  Min
                </label>
                <input
                  className="w-full border border-neutral-300 rounded-md px-3 py-2 text-sm bg-white"
                  value={minPrice}
                  onChange={(e) => setMinPrice(e.target.value)}
                  inputMode="decimal"
                />
              </div>
              <div>
                <label className="block text-xs text-neutral-500 mb-1">
                  Max
                </label>
                <input
                  className="w-full border border-neutral-300 rounded-md px-3 py-2 text-sm bg-white"
                  value={maxPrice}
                  onChange={(e) => setMaxPrice(e.target.value)}
                  inputMode="decimal"
                />
              </div>
            </div>
          </section>
        </div>

        {/* Footer */}
        <div className="px-5 pb-4 pt-2 border-t border-neutral-200 flex flex-col gap-2">
          <button
            className="w-full bg-blue-600 text-white text-sm font-semibold py-2 rounded-md hover:bg-blue-700 transition"
            onClick={handleApply}
          >
            Appliquer les filtres
          </button>
          <button
            className="w-full border border-orange-400 text-orange-600 text-sm font-semibold py-2 rounded-md bg-white hover:bg-orange-50 transition"
            onClick={handleReset}
          >
            Réinitialiser
          </button>
        </div>
      </div>
    </div>
  );
}
