export interface User {
  id: number;
  name: string;
  email: string;
  role: "seller" | "client";
  phone?: string | null;
  avatarUrl?: string | null;
  address?: string | null;
  businessName?: string | null;
  dateOfBirth?: string | null;
}
