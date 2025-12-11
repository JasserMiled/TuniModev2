"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

import AppHeader from "@/src/components/AppHeader";
import NewListingModal from "@/src/components/NewListingModal";

export default function NewListingPage() {
  const router = useRouter();
  const [open, setOpen] = useState(true);

  return (
    <main className="bg-gray-50 min-h-screen">
      <AppHeader />
      <NewListingModal
        open={open}
        onClose={() => {
          setOpen(false);
          router.back();
        }}
      />
    </main>
  );
}
