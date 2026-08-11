import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/server.ts", "src/firebase.ts"],
  format: ["cjs"],
  platform: "node",
  target: "node22",
  outDir: "dist",
  clean: true,
  sourcemap: true,
  splitting: false,
  dts: false,
  // Runtime packages stay external for Firebase deploy / node_modules resolution.
  external: [
    "firebase-admin",
    "firebase-functions",
    "firebase-functions/v2/https",
    "firebase-functions/params",
  ],
  esbuildOptions(options) {
    options.alias = {
      "@": "./src",
    };
  },
});
