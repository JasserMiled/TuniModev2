export interface Order {
  id: number;
  listingId: number;
  listingTitle: string;
  quantity: number;
  totalAmount: number;
  status: string;
  receptionMode: string;
  createdAt: string;
  sellerId?: number | null;
  sellerName?: string | null;
  buyerId?: number | null;
  buyerName?: string | null;
  color?: string | null;
  size?: string | null;
  shippingAddress?: string | null;
  phone?: string | null;
  buyerNote?: string | null;
}
