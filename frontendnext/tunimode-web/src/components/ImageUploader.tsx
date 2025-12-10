"use client";

import { ChangeEvent } from "react";

type ImageUploaderProps = {
  onUpload: (file: File) => void | Promise<void>;
  loading?: boolean;
};

const labelStyles =
  "border border-dashed border-neutral-300 rounded-lg p-4 flex flex-col items-center justify-center gap-2 cursor-pointer hover:border-blue-500 hover:text-blue-600 transition";

export default function ImageUploader({ onUpload, loading = false }: ImageUploaderProps) {
  const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    const imageFiles = Array.from(files).filter((file) =>
      file.type.startsWith("image/")
    );

    if (imageFiles.length === 0) {
      alert("Veuillez sélectionner un fichier image.");
      event.target.value = "";
      return;
    }

    imageFiles.forEach(onUpload);
    event.target.value = "";
  };

  return (
    <label className={labelStyles}>
      <span className="text-sm font-medium">
        {loading ? "Téléversement en cours..." : "Choisir une image"}
      </span>
      <input
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={handleChange}
        disabled={loading}
      />
      <p className="text-xs text-neutral-500">Formats acceptés : images uniquement.</p>
    </label>
  );
}
