"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { ApiService } from "@/src/services/api";
import { User } from "@/src/models/User";

type AuthState = {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  register: (payload: {
    name: string;
    email: string;
    password: string;
    role: string;
    phone?: string;
    address?: string;
  }) => Promise<boolean>;
  logout: () => void;
  refreshUser: (user: User | null) => void;
};

const AuthContext = createContext<AuthState | undefined>(undefined);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(ApiService.user ?? null);
  const [token, setToken] = useState<string | null>(ApiService.token ?? null);
  const [loading, setLoading] = useState(false);

  const login = useCallback(async (email: string, password: string) => {
    setLoading(true);
    const ok = await ApiService.login({ email, password });
    setUser(ApiService.user ?? null);
    setToken(ApiService.token ?? null);
    setLoading(false);
    return ok;
  }, []);

  const register = useCallback(async (payload: {
    name: string;
    email: string;
    password: string;
    role: string;
    phone?: string;
    address?: string;
  }) => {
    setLoading(true);
    const ok = await ApiService.register(payload);
    setLoading(false);
    return ok;
  }, []);

  const logout = useCallback(() => {
    ApiService.logout();
    setUser(null);
    setToken(null);
  }, []);

  const refreshUser = useCallback((updated: User | null) => {
    setUser(updated);
  }, []);

  const value = useMemo(
    () => ({ user, token, loading, login, logout, register, refreshUser }),
    [user, token, loading, login, logout, register, refreshUser]
  );

  useEffect(() => {
    if (token && user) {
      ApiService.setAuth(token, user);
    }
  }, [token, user]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
