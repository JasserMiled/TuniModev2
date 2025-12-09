"use client";

import { useState } from "react";
import { Protected } from "@/src/components/app/Protected";
import { useAuth } from "@/src/context/AuthContext";
import { ApiService } from "@/src/services/api";

export default function AccountSettingsPage() {
  const { user, refreshUser, logout } = useAuth();
  const [name, setName] = useState(user?.name ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [address, setAddress] = useState(user?.address ?? "");
  const [message, setMessage] = useState<string | null>(null);

  const handleSave = async () => {
    try {
      const updated = await ApiService.updateProfile({ name, email, address });
      refreshUser(updated);
      setMessage("Profil mis à jour");
    } catch (e) {
      setMessage((e as Error).message);
    }
  };

  const handleDelete = async () => {
    try {
      await ApiService.deleteAccount();
      logout();
    } catch (e) {
      setMessage((e as Error).message);
    }
  };

  return (
    <Protected>
      <div className="max-w-3xl mx-auto px-4 py-8 space-y-4">
        <h1 className="text-2xl font-semibold">Paramètres du compte</h1>
        <div className="space-y-3">
          <div className="space-y-1">
            <label className="text-sm text-neutral-600">Nom</label>
            <input className="w-full border rounded-lg px-3 py-2" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="space-y-1">
            <label className="text-sm text-neutral-600">Email</label>
            <input className="w-full border rounded-lg px-3 py-2" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div className="space-y-1">
            <label className="text-sm text-neutral-600">Adresse</label>
            <input className="w-full border rounded-lg px-3 py-2" value={address ?? ""} onChange={(e) => setAddress(e.target.value)} />
          </div>
          <button onClick={handleSave} className="px-4 py-2 bg-blue-600 text-white rounded-lg">
            Enregistrer
          </button>
          <button onClick={handleDelete} className="px-4 py-2 border rounded-lg text-red-600">
            Supprimer mon compte
          </button>
          {message && <p className="text-sm text-neutral-700">{message}</p>}
        </div>
      </div>
    </Protected>
  );
}
