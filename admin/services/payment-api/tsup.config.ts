import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/server.ts"],
  format: ["cjs"],
  platform: "node",
  target: "node20",
  outDir: "dist",
  clean: true,
  sourcemap: true,
  splitting: false,
  dts: false,
  esbuildOptions(options) {
    options.alias = {
      "@": "./src",
    };
  },
});
