import { cn } from "@/lib/utils";
import type { Band } from "@/types";

interface BandAvatarProps {
  band: Pick<Band, "avatar_color" | "avatar_emoji" | "avatar_url" | "name">;
  size?: number;
  className?: string;
}

/**
 * Displays a band avatar. Prefers the uploaded image, falls back to an
 * emoji on a solid color circle — matches iOS `BandAvatarView`.
 */
export function BandAvatar({ band, size = 56, className }: BandAvatarProps) {
  const dimension = { width: size, height: size };

  if (band.avatar_url) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={band.avatar_url}
        alt={band.name}
        style={dimension}
        className={cn(
          "rounded-2xl object-cover ring-1 ring-divider",
          className,
        )}
      />
    );
  }

  return (
    <div
      style={{
        ...dimension,
        backgroundColor: band.avatar_color || "#2563EB",
        fontSize: size * 0.5,
      }}
      className={cn(
        "flex items-center justify-center rounded-2xl ring-1 ring-divider",
        className,
      )}
    >
      <span aria-hidden>{band.avatar_emoji || "🎵"}</span>
    </div>
  );
}
