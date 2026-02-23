import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
    base: '/benchmark/',
    publicDir: '../Public',
    resolve: {
        alias: {
            '@bjorn3/browser_wasi_shim': resolve(__dirname, 'node_modules/@bjorn3/browser_wasi_shim')
        }
    },
    build: {
        target: 'esnext',
        assetsDir: 'assets',
        rollupOptions: {
            input: {
                play: resolve(__dirname, 'play.html'),
            },
        },
    },
    server: {
        watch: {
            ignored: [
            ],
        },
        headers: {
            "Cross-Origin-Opener-Policy": "same-origin",
            "Cross-Origin-Embedder-Policy": "require-corp",
        },
    }
});
