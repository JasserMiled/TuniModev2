"use client";

import { ReactNode, useEffect } from "react";

type DrawerProps = {
  open: boolean;
  onClose: () => void;
  side?: "left" | "right";
  title?: string;
  children: ReactNode;
};

export default function Drawer({
  open,
  onClose,
  side = "left",
  title,
  children,
}: DrawerProps) {
  // Close on ESC
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    if (open) document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  return (
    <>
      {/* Overlay */}
      <div
        className={`fixed inset-0 bg-black/30 z-40 transition-opacity duration-300 ${
          open ? "opacity-100 pointer-events-auto" : "opacity-0 pointer-events-none"
        }`}
        onClick={onClose}
      />

      {/* Drawer */}
      <div
        className={`
          fixed inset-y-0 z-50 w-72 bg-white shadow-xl overflow-y-auto
          transition-transform duration-300 ease-out
          ${side === "left" ? "left-0" : "right-0"}
          ${
            open
              ? "translate-x-0"
              : side === "left"
              ? "-translate-x-full"
              : "translate-x-full"
          }
        `}
      >
        {title && (
          <div className="px-4 py-5 border-b border-neutral-200 flex items-center justify-between">
            <span className="text-lg font-semibold text-neutral-900">
              {title}
            </span>
            <button
              onClick={onClose}
              className="p-2 rounded-full hover:bg-neutral-100"
              aria-label="Fermer"
            >
              ✕
            </button>
          </div>
        )}

        {children}
      </div>
    </>
  );
}
