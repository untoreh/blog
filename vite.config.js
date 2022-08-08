import { defineConfig } from "vite";
import autoprefixer from "autoprefixer";
import critical from 'rollup-plugin-critical'

// https://vitejs.dev/config/
export default defineConfig({
  root: "/tmp/__site",
  publicDir: "__site",
  resolve: {
    alias: [],
    extensions: [".mjs", ".js", ".ts", ".jsx", ".tsx", ".json", ".vue", ".scss",],
  },
  plugins: [
    critical({
      criticalUrl: 'http://localhost:8000',
      criticalBase: './',
      criticalPages: [
        { uri: '' },
        { uri: '/tag' },
        { uri: '/posts' },
        { uri: '/tag/about' },
        { uri: '/posts/alpine' }
      ],
      criticalConfig: {
        inline: false,
        base: "__site",
        target: {
          css: "../dist/bundle-crit.css",
          uncritical: '../dist/bundle.css',
        },
        ignore: {
          atrule: ['@font-face'],
          rule: [/.*\/assets\/flags\.png.*/]
        },
        rebase: {
          from: '/assets/flags.png',
          to: '/assets/flags.png',
        },
        dimensions: [
          {
            width: 1200,
          },
          {
            width: 600,
          },
          {
            width: 400,
          },
          {
            width: 200,
          },
        ],
      }
    }),
  ],
  css: {
    postcss: {
      plugins: [autoprefixer()],
    },
  },
  build: {
    rollupOptions: {
      output: {
        // entryFileNames: `[name].js`,
        // chunkFileNames: `[name].js`,
        assetFileNames: `assets/[name].[ext]`
      }
    }
  }
});
