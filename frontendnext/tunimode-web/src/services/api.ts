import { FavoriteCollections } from "@/src/models/Favorite";
import { Category } from "@/src/models/Category";
import { Listing } from "@/src/models/Listing";
import { Order } from "@/src/models/Order";
import { Review } from "@/src/models/Review";
import { User } from "@/src/models/User";

const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:4000";

let authToken: string | null = null;
let currentUser: User | null = null;

const jsonHeaders = (withAuth = false) => {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (withAuth && authToken) {
    headers["Authorization"] = `Bearer ${authToken}`;
  }
  return headers;
};

const handleResponse = async <T>(res: Response, defaultError: string): Promise<T> => {
  if (!res.ok) {
    let message = defaultError;
    try {
      const data = await res.json();
      message = (data as Record<string, unknown>)["message"] as string ?? message;
    } catch (e) {
      // ignore
    }
    throw new Error(message);
  }
  return res.json() as Promise<T>;
};

export const ApiService = {
  get baseUrl() {
    return baseURL;
  },
  resolveImageUrl(url?: string | null) {
    if (!url) return null;
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    const normalized = url.startsWith("/") ? url : `/${url}`;
    return `${baseURL}${normalized}`;
  },
  get token() {
    return authToken;
  },
  get user() {
    return currentUser;
  },
  setAuth(token: string | null, user?: User | null) {
    authToken = token;
    if (user !== undefined) {
      currentUser = user;
    }
  },

  async register(payload: {
    name: string;
    email: string;
    password: string;
    role: string;
    phone?: string;
    address?: string;
  }): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/auth/register`, {
      method: "POST",
      headers: jsonHeaders(),
      body: JSON.stringify(payload),
    });
    return res.status === 201 || res.status === 200;
  },

  async login(payload: { email: string; password: string }): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/auth/login`, {
      method: "POST",
      headers: jsonHeaders(),
      body: JSON.stringify(payload),
    });

    if (!res.ok) return false;
    const data = (await res.json()) as { user: User; token: string };
    currentUser = data.user;
    authToken = data.token;
    return true;
  },

  logout() {
    authToken = null;
    currentUser = null;
  },

  async uploadProfileImage(file: File): Promise<string> {
    const form = new FormData();
    form.append("image", file);
    const res = await fetch(`${baseURL}/api/upload/image`, {
      method: "POST",
      headers: authToken ? { Authorization: `Bearer ${authToken}` } : undefined,
      body: form,
    });
    const data = await handleResponse<{ url: string }>(res, "Upload impossible");
    return data.url;
  },

  async updateProfile(payload: {
    name?: string;
    address?: string;
    email?: string;
    phone?: string;
    currentPassword?: string;
    newPassword?: string;
    avatarUrl?: string;
  }): Promise<User> {
    const res = await fetch(`${baseURL}/api/auth/me`, {
      method: "PUT",
      headers: jsonHeaders(true),
      body: JSON.stringify({
        name: payload.name,
        address: payload.address,
        email: payload.email,
        phone: payload.phone,
        current_password: payload.currentPassword,
        new_password: payload.newPassword,
        avatar_url: payload.avatarUrl,
      }),
    });
    const data = await handleResponse<{ user?: User } & Record<string, unknown>>(res, "Mise à jour impossible");
    const updated = data.user ?? (data as unknown as User);
    currentUser = updated;
    return updated;
  },

  async deleteAccount(): Promise<void> {
    const res = await fetch(`${baseURL}/api/auth/me`, {
      method: "DELETE",
      headers: jsonHeaders(true),
    });
    if (!res.ok) {
      const data = await res.json();
      throw new Error((data as Record<string, unknown>)["message"] as string ?? "Suppression impossible");
    }
    authToken = null;
    currentUser = null;
  },

  async fetchFavorites(): Promise<FavoriteCollections> {
    const res = await fetch(`${baseURL}/api/favorites/me`, {
      headers: jsonHeaders(true),
    });
    return handleResponse<FavoriteCollections>(res, "Impossible de charger vos favoris");
  },

  async addFavoriteListing(listingId: number): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/favorites/listings/${listingId}`, {
      method: "POST",
      headers: jsonHeaders(true),
    });
    return res.ok;
  },

  async removeFavoriteListing(listingId: number): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/favorites/listings/${listingId}`, {
      method: "DELETE",
      headers: jsonHeaders(true),
    });
    return res.ok;
  },

  async addFavoriteSeller(sellerId: number): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/favorites/sellers/${sellerId}`, {
      method: "POST",
      headers: jsonHeaders(true),
    });
    return res.ok;
  },

  async removeFavoriteSeller(sellerId: number): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/favorites/sellers/${sellerId}`, {
      method: "DELETE",
      headers: jsonHeaders(true),
    });
    return res.ok;
  },

  async fetchUserProfile(userId: number): Promise<User> {
    const res = await fetch(`${baseURL}/api/auth/user/${userId}`, {
      headers: jsonHeaders(),
    });
    const data = await handleResponse<{ user: User }>(res, "Impossible de charger le profil utilisateur");
    return data.user;
  },

  async fetchListings(params: {
    query?: string;
    gender?: string;
    city?: string;
    minPrice?: number;
    maxPrice?: number;
    categoryId?: number;
    sizes?: string[];
    colors?: string[];
    deliveryAvailable?: boolean;
  } = {}): Promise<Listing[]> {
    const queryParams = new URLSearchParams();
    if (params.query) queryParams.set("q", params.query.trim());
    if (params.gender) queryParams.set("gender", params.gender.trim().toLowerCase());
    if (params.city) queryParams.set("city", params.city.trim());
    if (params.minPrice !== undefined) queryParams.set("min_price", String(params.minPrice));
    if (params.maxPrice !== undefined) queryParams.set("max_price", String(params.maxPrice));
    if (params.categoryId !== undefined) queryParams.set("category_id", String(params.categoryId));
    if (params.sizes?.length) queryParams.set("sizes", params.sizes.join(","));
    if (params.colors?.length) queryParams.set("colors", params.colors.join(","));
    if (params.deliveryAvailable !== undefined)
      queryParams.set("delivery_available", String(params.deliveryAvailable));

    const url = queryParams.toString()
      ? `${baseURL}/api/listings?${queryParams.toString()}`
      : `${baseURL}/api/listings`;
    const res = await fetch(url, { headers: jsonHeaders() });
    return handleResponse<Listing[]>(res, "Erreur lors du chargement des annonces");
  },

  async fetchMyListings(): Promise<Listing[]> {
    const res = await fetch(`${baseURL}/api/listings/me/mine`, {
      headers: jsonHeaders(true),
    });
    return handleResponse<Listing[]>(res, "Impossible de charger vos annonces");
  },

  async fetchListingDetail(id: number): Promise<Listing> {
    const res = await fetch(`${baseURL}/api/listings/${id}`, {
      headers: jsonHeaders(!!authToken),
    });
    return handleResponse<Listing>(res, "Annonce introuvable");
  },

  async fetchUserListings(userId: number): Promise<Listing[]> {
    const res = await fetch(`${baseURL}/api/listings/user/${userId}`, {
      headers: jsonHeaders(),
    });
    return handleResponse<Listing[]>(res, "Impossible de charger les annonces de cet utilisateur");
  },

  async updateListing(payload: {
    id: number;
    title?: string;
    description?: string;
    price?: number;
    sizes?: string[];
    colors?: string[];
    condition?: string;
    categoryId?: number;
    city?: string;
    deliveryAvailable?: boolean;
    status?: string;
    stock?: number;
  }): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/listings/${payload.id}`, {
      method: "PUT",
      headers: jsonHeaders(true),
      body: JSON.stringify({
        title: payload.title,
        description: payload.description,
        price: payload.price,
        sizes: payload.sizes,
        colors: payload.colors,
        condition: payload.condition,
        category_id: payload.categoryId,
        city: payload.city,
        delivery_available: payload.deliveryAvailable,
        status: payload.status,
        stock: payload.stock,
      }),
    });
    return res.status === 200;
  },

  async deleteListing(id: number): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/listings/${id}`, {
      method: "DELETE",
      headers: jsonHeaders(true),
    });
    return res.status === 200;
  },

  async createListing(payload: {
    title: string;
    description: string;
    price: number;
    sizes?: string[];
    colors?: string[];
    condition?: string;
    categoryId?: number;
    city?: string;
    images?: string[];
    deliveryAvailable?: boolean;
  }): Promise<boolean> {
    const res = await fetch(`${baseURL}/api/listings`, {
      method: "POST",
      headers: jsonHeaders(true),
      body: JSON.stringify({
        title: payload.title,
        description: payload.description,
        price: payload.price,
        sizes: payload.sizes ?? [],
        colors: payload.colors ?? [],
        condition: payload.condition,
        category_id: payload.categoryId,
        city: payload.city,
        delivery_available: payload.deliveryAvailable ?? false,
        images: payload.images ?? [],
      }),
    });
    return res.status === 201;
  },

  async fetchCategoryTree(): Promise<Category[]> {
    const res = await fetch(`${baseURL}/api/categories/tree`, { headers: jsonHeaders() });
    return handleResponse<Category[]>(res, "Impossible de charger les catégories");
  },

  async fetchSizesForCategory(categoryId: number): Promise<string[]> {
    const res = await fetch(`${baseURL}/api/sizes?category_id=${categoryId}`, { headers: jsonHeaders() });
    const data = await handleResponse<Array<{ label?: string }>>(res, "Impossible de charger les tailles");
    return data
      .map((item) => item.label?.toString() ?? "")
      .filter((label) => label.trim().length > 0);
  },

  async uploadImage(file: File): Promise<string | null> {
    const form = new FormData();
    form.append("image", file);
    const res = await fetch(`${baseURL}/api/upload/image`, {
      method: "POST",
      headers: authToken ? { Authorization: `Bearer ${authToken}` } : undefined,
      body: form,
    });
    if (res.status === 201) {
      const data = (await res.json()) as { url?: string };
      return data.url ?? null;
    }
    return null;
  },

  async createOrder(payload: {
    listingId: number;
    quantity: number;
    receptionMode: string;
    color?: string;
    size?: string;
    shippingAddress?: string;
    phone?: string;
    buyerNote?: string;
  }): Promise<Record<string, unknown>> {
    const res = await fetch(`${baseURL}/api/orders`, {
      method: "POST",
      headers: jsonHeaders(true),
      body: JSON.stringify({
        listing_id: payload.listingId,
        quantity: payload.quantity,
        reception_mode: payload.receptionMode,
        color: payload.color,
        size: payload.size,
        shipping_address: payload.shippingAddress,
        phone: payload.phone,
        buyer_note: payload.buyerNote,
      }),
    });
    return handleResponse<Record<string, unknown>>(res, "Commande impossible");
  },

  async fetchBuyerOrders(): Promise<Order[]> {
    const res = await fetch(`${baseURL}/api/orders/me/buyer`, {
      headers: jsonHeaders(true),
    });
    return handleResponse<Order[]>(res, "Impossible de charger vos commandes");
  },

  async fetchSellerOrders(): Promise<Order[]> {
    const res = await fetch(`${baseURL}/api/orders/me/seller`, {
      headers: jsonHeaders(true),
    });
    return handleResponse<Order[]>(res, "Impossible de charger vos demandes de commandes");
  },

  async updateSellerOrderStatus(orderId: number, status: string): Promise<Order> {
    const res = await fetch(`${baseURL}/api/orders/${orderId}/status`, {
      method: "PATCH",
      headers: jsonHeaders(true),
      body: JSON.stringify({ status }),
    });
    return handleResponse<Order>(res, "Mise à jour impossible");
  },

  async cancelOrder(orderId: number): Promise<Order> {
    const res = await fetch(`${baseURL}/api/orders/${orderId}/status`, {
      method: "PATCH",
      headers: jsonHeaders(true),
      body: JSON.stringify({ status: "cancelled" }),
    });
    return handleResponse<Order>(res, "Impossible d'annuler la commande");
  },

  async confirmOrderReception(orderId: number): Promise<Order> {
    const res = await fetch(`${baseURL}/api/orders/${orderId}/status`, {
      method: "PATCH",
      headers: jsonHeaders(true),
      body: JSON.stringify({ status: "received" }),
    });
    return handleResponse<Order>(res, "Impossible de confirmer la réception");
  },

  async refuseOrderReception(orderId: number): Promise<Order> {
    const res = await fetch(`${baseURL}/api/orders/${orderId}/status`, {
      method: "PATCH",
      headers: jsonHeaders(true),
      body: JSON.stringify({ status: "reception_refused" }),
    });
    return handleResponse<Order>(res, "Impossible de refuser la réception");
  },

  async fetchUserReviews(userId: number): Promise<Review[]> {
    const res = await fetch(`${baseURL}/api/reviews/user/${userId}`, {
      headers: jsonHeaders(),
    });
    return handleResponse<Review[]>(res, "Impossible de charger les avis de cet utilisateur");
  },

  async fetchOrderReviews(orderId: number): Promise<Review[]> {
    const res = await fetch(`${baseURL}/api/reviews/order/${orderId}`, {
      headers: jsonHeaders(true),
    });
    return handleResponse<Review[]>(res, "Impossible de charger les avis de cette commande");
  },

  async submitReview(payload: { orderId: number; rating: number; comment?: string }): Promise<Review> {
    const res = await fetch(`${baseURL}/api/reviews`, {
      method: "POST",
      headers: jsonHeaders(true),
      body: JSON.stringify({
        order_id: payload.orderId,
        rating: payload.rating,
        comment: payload.comment,
      }),
    });
    return handleResponse<Review>(res, "Impossible d'enregistrer votre avis pour cette commande");
  },
};
