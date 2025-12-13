"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/src/context/AuthContext";

export default function RegisterPage() {
  const router = useRouter();
  const { register, loading } = useAuth();
  const [role, setRole] = useState("client");
  const [name, setName] = useState("");
  const [businessName, setBusinessName] = useState("");
  const [description, setDescription] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const ok = await register({
      name,
      email,
      password,
      role,
      phone,
      businessName: role === "seller" ? businessName : undefined,
      description: role === "seller" ? description : undefined,
      dateOfBirth: role === "client" ? dateOfBirth : undefined,
    });
    if (!ok) {
      setError("Inscription impossible");
    } else {
      router.push("/auth/login");
    }
  };

  return (
    <div className="max-w-md mx-auto px-4 py-10 space-y-4">
      <h1 className="text-2xl font-semibold">Créer un compte</h1>
      <div className="flex gap-2 text-sm">
        <button
          onClick={() => setRole("client")}
          className={`px-3 py-2 rounded-lg border ${role === "client" ? "bg-blue-600 text-white" : ""}`}
        >
          Client
        </button>
        <button
          onClick={() => setRole("seller")}
          className={`px-3 py-2 rounded-lg border ${role === "seller" ? "bg-blue-600 text-white" : ""}`}
        >
          Vendeur
        </button>
      </div>
      <form onSubmit={handleSubmit} className="space-y-3">
        {role === "seller" && (
          <div className="space-y-3">
            <input
              className="w-full border rounded-lg px-3 py-2"
              placeholder="Nom de la boutique"
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
            />

            <textarea
              className="w-full border rounded-lg px-3 py-2"
              placeholder="Description de votre boutique"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
            />
          </div>
        )}
        <input
          className="w-full border rounded-lg px-3 py-2"
          placeholder="Nom"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <input
          className="w-full border rounded-lg px-3 py-2"
          placeholder="Email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <input
          className="w-full border rounded-lg px-3 py-2"
          placeholder="Téléphone"
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
        />
        {role === "client" && (
          <div className="space-y-1">
            <label className="text-sm text-neutral-700" htmlFor="dob">
              Date de naissance
            </label>
            <input
              id="dob"
              className="w-full border rounded-lg px-3 py-2"
              type="date"
              value={dateOfBirth}
              onChange={(e) => setDateOfBirth(e.target.value)}
            />
          </div>
        )}
        <input
          className="w-full border rounded-lg px-3 py-2"
          placeholder="Mot de passe"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        {error && <p className="text-red-600 text-sm">{error}</p>}
        <button type="submit" className="w-full bg-blue-600 text-white py-2 rounded-lg" disabled={loading}>
          {loading ? "Création..." : "S'inscrire"}
        </button>
      </form>
      <p className="text-sm text-neutral-600">
        Déjà inscrit ? <Link href="/auth/login" className="text-blue-600 underline">Connexion</Link>
      </p>
    </div>
  );
}
