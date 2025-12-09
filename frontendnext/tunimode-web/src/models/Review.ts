export interface Review {
  id: number;
  orderId: number;
  reviewerId: number;
  revieweeId: number;
  rating: number;
  comment?: string | null;
  createdAt: string;
  reviewerName?: string | null;
}
