import path from "node:path";
import { fileURLToPath } from "node:url";
import type { NextConfig } from "next";

const projectRoot = path.dirname(fileURLToPath(import.meta.url));

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  images: {
    formats: ["image/avif", "image/webp"],
    qualities: [75, 85, 90],
    // Prefer sharper responsive variants for destination cards / Retina.
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [64, 96, 128, 256, 384, 640, 750],
    minimumCacheTTL: 60 * 60 * 24 * 30,
  },
  turbopack: {
    root: projectRoot,
  },
};

export default nextConfig;
