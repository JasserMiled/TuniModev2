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
  clientId?: number | null;
  clientName?: string | null;
  color?: string | null;
  size?: string | null;
  shippingAddress?: string | null;
  phone?: string | null;
  clientNote?: string | null;
}
