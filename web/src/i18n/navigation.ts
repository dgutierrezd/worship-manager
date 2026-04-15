import { createNavigation } from "next-intl/navigation";
import { routing } from "./routing";

/**
 * Locale-aware replacements for Next.js navigation primitives. Use these
 * throughout the app instead of `next/link` / `next/navigation` so links
 * automatically preserve / apply the current locale prefix.
 */
export const { Link, redirect, usePathname, useRouter, getPathname } =
  createNavigation(routing);
