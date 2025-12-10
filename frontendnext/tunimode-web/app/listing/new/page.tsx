"use client";

import { useState } from "react";
import AppHeader from "@/src/components/AppHeader";
import ImageUploader from "@/src/components/ImageUploader";
import { uploadImage } from "@/src/services/uploadService";

export default function ListingUploadPage() {
  const [gallery, setGallery] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleUpload = async (file: File) => {
    setUploading(true);
    setError(null);
    try {
      const url = await uploadImage(file, "listing");
      setGallery((prev) => [...prev, url]);
    } catch (e) {
      const message = e instanceof Error ? e.message : "Impossible de téléverser l'image.";
      setError(message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <main className="bg-gray-50 min-h-screen">
      <AppHeader />
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
        <div className="bg-white border rounded-xl shadow-sm p-6 space-y-4">
          <div>
            <p className="text-sm text-neutral-500">Nouvelle annonce</p>
            <h1 className="text-2xl font-semibold">Téléverser des images</h1>
            <p className="text-sm text-neutral-600 mt-1">
              Ajoutez plusieurs images pour mettre en valeur votre annonce. Chaque envoi
              utilise le service d'upload centralisé.
            </p>
          </div>

          <ImageUploader onUpload={handleUpload} loading={uploading} />
          {error && <p className="text-sm text-red-600">{error}</p>}

          <div>
            <h2 className="text-lg font-semibold mb-3">Galerie téléversée</h2>
            {gallery.length === 0 ? (
              <p className="text-sm text-neutral-500">Aucune image pour le moment.</p>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                {gallery.map((url) => (
                  <div
                    key={url}
                    className="relative w-full pt-[100%] bg-neutral-100 rounded-lg overflow-hidden border"
                  >
                    <img
                      src={url}
                      alt="Image de l'annonce"
                      className="absolute inset-0 w-full h-full object-cover"
                    />
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
