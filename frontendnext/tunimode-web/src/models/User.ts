export interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  phone?: string | null;
  avatarUrl?: string | null;
  address?: string | null;
}
