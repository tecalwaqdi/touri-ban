import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Touri Taxi",
    short_name: "Touri",
    description: "Touri Taxi — smart travel and taxi service",
    start_url: "/ar",
    display: "standalone",
    background_color: "#f6f3ec",
    theme_color: "#1f6f5f",
    icons: [
      {
        src: "/apple-touch-icon.png",
        sizes: "1024x1024",
        type: "image/png",
      },
    ],
  };
}
