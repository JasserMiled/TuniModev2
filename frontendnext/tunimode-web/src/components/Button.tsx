"use client";

import { useState } from "react";
import { colors } from "@/src/styles/theme";

type ButtonVariant = "primary" | "secondary" | "success" | "warning" | "error";
type ButtonSize = "sm" | "md" | "lg";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  width?: string | number;
  height?: string | number;
  fullWidth?: boolean;
  className?: string; // ← IMPORTANT
  children: React.ReactNode;
}

const getStyles = (variant: ButtonVariant, size: ButtonSize, hover: boolean) => {
  const sizes = {
    sm: { padding: "6px 12px", fontSize: "14px" },
    md: { padding: "10px 16px", fontSize: "16px" },
    lg: { padding: "14px 24px", fontSize: "18px" },
  };

  const variants = {
    primary: {
      backgroundColor: hover ? "#025a9f" : colors.primary,
      color: "#fff",
      border: "none",
    },
    secondary: {
      backgroundColor: hover ? "rgba(39, 101, 245, 0.08)" : "transparent",
      color: colors.primary,
      border: `2px solid ${colors.primary}`,
    },
    success: {
      backgroundColor: hover ? "#66BB6A" : colors.success,
      color: "#fff",
      border: "none",
    },
    warning: {
      backgroundColor: hover ? "#FFA726" : colors.warning,
      color: "#fff",
      border: "none",
    },
    error: {
      backgroundColor: hover ? "#EF5350" : colors.error,
      color: "#fff",
      border: "none",
    },
  };

  return {
    borderRadius: "4px",
    fontWeight: 400,
    cursor: "pointer",
    transition: "background-color 0.15s ease, opacity 0.15s ease",
    ...sizes[size],
    ...variants[variant],
  };
};

export default function Button({
  variant = "primary",
  size = "md",
  width,
  height,
  fullWidth = false,
  disabled,
  className = "",
  children,
  ...props
}: ButtonProps) {
  const [hovered, setHovered] = useState(false);

  return (
    <button
      {...props}
      className={className} // ← TAILWIND SUPPORT TOTAL
      disabled={disabled}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        ...getStyles(variant, size, hovered && !disabled),
        width: fullWidth ? "100%" : width,
        height,
        lineHeight: height ? `${height}px` : undefined,
        padding: height ? "0 16px" : undefined,
        opacity: disabled ? 0.6 : 1,
        cursor: disabled ? "not-allowed" : "pointer",
      }}
    >
      {children}
    </button>
  );
}
