export interface Listing {
  id: number;
  userId: number;
  title: string;
  description?: string | null;
  price: number;
  imageUrl: string;
  sizes: string[];
  colors: string[];
  gender?: string | null;
  condition?: string | null;
  city?: string | null;
  deliveryAvailable: boolean;
  categoryName?: string | null;
  sellerName?: string | null;
  imageUrls: string[];
  stock: number;
  status?: string | null;
  isDeleted: boolean;
}
