"use client";

import { useEffect, useMemo, useState } from "react";
import { Protected } from "@/src/components/app/Protected";
import { useAuth } from "@/src/context/AuthContext";
import { ApiService } from "@/src/services/api";
import AppHeader from "@/src/components/AppHeader";

export default function AccountSettingsPage() {
  const { user, refreshUser, logout } = useAuth();

  const [name, setName] = useState(user?.name ?? "");
  const [address, setAddress] = useState(user?.address ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [phone, setPhone] = useState(user?.phone ?? "");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");

  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarError, setAvatarError] = useState(false);

  const [tab, setTab] = useState<"general" | "security">("general");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const activeTab =
    "pb-2 border-b-2 border-blue-600 text-blue-600 font-semibold";
  const inactiveTab =
    "pb-2 border-b-2 border-transparent text-neutral-500 hover:text-neutral-800";

  const handleUpdateGeneral = async () => {
    try {
      setError(null);
      const updated = await ApiService.updateProfile({ name, address });
      refreshUser(updated);
      setMessage("Informations mises à jour");
    } catch (e) {
      setError((e as Error).message);
    }
  };

  const handleUpdateSecurity = async () => {
    setMessage(null);

    if ((currentPassword && !newPassword) || (!currentPassword && newPassword)) {
      setError("Remplissez les deux champs pour changer le mot de passe.");
      return;
    }

    try {
      setError(null);
      const updated = await ApiService.updateProfile({
        email,
        phone,
        currentPassword: currentPassword || undefined,
        newPassword: newPassword || undefined,
      });

      refreshUser(updated);
      setMessage("Paramètres de sécurité mis à jour");

      setCurrentPassword("");
      setNewPassword("");
    } catch (e) {
      setError((e as Error).message);
    }
  };

  const handleDeleteAccount = async () => {
    if (!confirm("Voulez-vous vraiment supprimer votre compte ?")) return;

    try {
      await ApiService.deleteAccount();
      logout();
    } catch (e) {
      setError((e as Error).message);
    }
  };

  const handleAvatarUpload = async () => {
    if (!avatarFile) return;

    try {
      const url = await ApiService.uploadProfileImage(avatarFile);
      const resolvedUrl = ApiService.resolveImageUrl(url) ?? url;
      const updated = await ApiService.updateProfile({ avatarUrl: resolvedUrl });
      refreshUser(updated);

      setAvatarFile(null);
      setMessage("Photo de profil mise à jour");
    } catch (e) {
      setError((e as Error).message);
    }
  };

  const avatarUrl = useMemo(
    () =>
      user?.avatarUrl
        ? ApiService.resolveImageUrl(user.avatarUrl) ?? user.avatarUrl
        : null,
    [user?.avatarUrl]
  );

  useEffect(() => {
    setAvatarError(false);
  }, [avatarUrl]);

  return (
    <Protected>
      <main className="bg-gray-50 min-h-screen">
        {/* ✅ SAME HEADER AS LISTINGS PAGE */}
        <AppHeader />

        <div className="max-w-3xl mx-auto px-4 py-10 space-y-6">
          <h1 className="text-2xl font-semibold mb-4">Paramètres du compte</h1>

        {/* Messages */}
        {message && (
          <div className="p-3 rounded-lg bg-green-100 text-green-700 border border-green-300">
            {message}
          </div>
        )}
        {error && (
          <div className="p-3 rounded-lg bg-red-100 text-red-700 border border-red-300">
            {error}
          </div>
        )}

        {/* --- TAB BAR (same style as My Listings) --- */}
        <div className="flex border-b mb-4 space-x-6">
          <button
            onClick={() => setTab("general")}
            className={tab === "general" ? activeTab : inactiveTab}
          >
            Informations générales
          </button>

          <button
            onClick={() => setTab("security")}
            className={tab === "security" ? activeTab : inactiveTab}
          >
            Sécurité
          </button>
        </div>

        {/* --- TAB CONTENT --- */}
        {tab === "general" && (
          <div className="space-y-6">
            {/* Avatar */}
            <div className="border rounded-xl p-4 flex items-center gap-4 bg-white">
              <div className="w-20 h-20 rounded-full overflow-hidden bg-neutral-200 flex items-center justify-center">
                {avatarFile ? (
                  <img
                    src={URL.createObjectURL(avatarFile)}
                    alt=""
                    className="w-full h-full object-cover"
                  />
                ) : avatarUrl && !avatarError ? (
                  <img
                    src={avatarUrl}
                    alt=""
                    className="w-full h-full object-cover"
                    onError={() => setAvatarError(true)}
                  />
                ) : (
                  <span aria-hidden className="text-neutral-500 text-4xl">
                    👤
                  </span>
                )}
              </div>

              <div className="flex flex-col gap-2">
                <input
                  type="file"
                  accept="image/*"
                  onChange={(e) => setAvatarFile(e.target.files?.[0] ?? null)}
                />
                {avatarFile && (
                  <button
                    className="px-3 py-1 bg-blue-600 text-white rounded-lg"
                    onClick={handleAvatarUpload}
                  >
                    Mettre à jour la photo
                  </button>
                )}
              </div>
            </div>

            {/* Name */}
            <div>
              <label className="text-sm text-neutral-600">Nom complet</label>
              <input
                className="w-full border rounded-lg px-3 py-2 mt-1 bg-white"
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </div>

            {/* Address */}
            <div>
              <label className="text-sm text-neutral-600">Adresse</label>
              <input
                className="w-full border rounded-lg px-3 py-2 mt-1 bg-white"
                value={address}
                onChange={(e) => setAddress(e.target.value)}
              />
            </div>

            <button
              className="px-4 py-2 bg-blue-600 text-white rounded-lg"
              onClick={handleUpdateGeneral}
            >
              Enregistrer
            </button>
          </div>
        )}

        {tab === "security" && (
          <div className="space-y-6">
            <div>
              <label className="text-sm text-neutral-600">Email</label>
              <input
                className="w-full border rounded-lg px-3 py-2 mt-1 bg-white"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div>
              <label className="text-sm text-neutral-600">Téléphone</label>
              <input
                className="w-full border rounded-lg px-3 py-2 mt-1 bg-white"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
              />
            </div>

            <p className="text-neutral-600 text-sm">
              Pour changer le mot de passe, remplissez les deux champs.
            </p>

            <input
              type="password"
              placeholder="Mot de passe actuel"
              className="w-full border rounded-lg px-3 py-2 bg-white"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
            />

            <input
              type="password"
              placeholder="Nouveau mot de passe"
              className="w-full border rounded-lg px-3 py-2 bg-white"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
            />

            <button
              className="px-4 py-2 bg-blue-600 text-white rounded-lg"
              onClick={handleUpdateSecurity}
            >
              Enregistrer
            </button>

            {/* Delete Account */}
            <div className="border p-4 rounded-xl bg-red-50">
              <h2 className="text-lg font-semibold text-red-700">
                Supprimer le compte
              </h2>
              <p className="text-red-700 text-sm">
                Cette action est irréversible.
              </p>

              <button
                className="mt-3 px-4 py-2 text-white bg-red-600 rounded-lg"
                onClick={handleDeleteAccount}
              >
                Supprimer mon compte
              </button>
            </div>
          </div>
        )}
      </div>
    </main>
  </Protected>
);

}
