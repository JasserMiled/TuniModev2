import { ApiService } from "@/src/services/api";

const API_URL = process.env.NEXT_PUBLIC_API_BASE_URL;

export type UploadType = "profile" | "listing";

export async function uploadImage(file: File, type: UploadType): Promise<string> {
  if (!API_URL) {
    throw new Error("NEXT_PUBLIC_API_BASE_URL is not configured.");
  }

  const formData = new FormData();
  formData.append("image", file);
  formData.append("type", type);

  const headers: HeadersInit = {};
  if (ApiService.token) {
    headers["Authorization"] = `Bearer ${ApiService.token}`;
  }

  const response = await fetch(`${API_URL}/api/upload/image`, {
    method: "POST",
    headers,
    body: formData,
  });

  if (!response.ok) {
    let message = "Échec du téléversement de l'image.";
    try {
      const data = (await response.json()) as { message?: string };
      if (data.message) message = data.message;
    } catch {
      // ignore parsing errors
    }
    throw new Error(message);
  }

  const payload = (await response.json()) as { url?: string };
  if (!payload?.url) {
    throw new Error("Aucune URL d'image renvoyée par le serveur.");
  }

  return payload.url;
}
