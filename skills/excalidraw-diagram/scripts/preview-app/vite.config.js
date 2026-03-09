import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 8091,
    open: false,
    // Proxy API calls to the backend preview server
    proxy: {
      '/api': {
        target: 'http://localhost:8092',
        changeOrigin: true,
      },
    },
  },
  define: {
    'process.env.IS_PREACT': JSON.stringify('false'),
  },
});
