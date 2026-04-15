import type { HTMLAttributes } from "react";
import { cn } from "@/lib/utils";

type Variant =
  | "default"
  | "accent"
  | "success"
  | "warning"
  | "danger"
  | "muted"
  | "outline";

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: Variant;
}

const styles: Record<Variant, string> = {
  default: "bg-surfaceMuted text-primary",
  accent: "bg-accentMuted text-accent ring-1 ring-inset ring-accent/20",
  success: "bg-success/12 text-success ring-1 ring-inset ring-success/25",
  warning: "bg-warning/15 text-warning ring-1 ring-inset ring-warning/25",
  danger: "bg-danger/12 text-danger ring-1 ring-inset ring-danger/25",
  muted: "bg-surfaceMuted text-secondary",
  outline: "border border-divider text-secondary",
};

export function Badge({ className, variant = "default", ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold",
        styles[variant],
        className,
      )}
      {...props}
    />
  );
}
