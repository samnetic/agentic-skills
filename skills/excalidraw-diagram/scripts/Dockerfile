FROM node:22-slim

WORKDIR /app

# Copy preview-app and install its dependencies
COPY preview-app/package.json preview-app/package-lock.json* preview-app/
RUN cd preview-app && npm install --silent

# Copy preview-app source
COPY preview-app/index.html preview-app/
COPY preview-app/vite.config.js preview-app/
COPY preview-app/src/ preview-app/src/

# Copy API server
COPY preview_server.mjs .

# Default ports: Vite=8091, API=8092
ENV PORT=8091
ENV API_PORT=8092

EXPOSE 8091

# Mount your .excalidraw file to /data/diagram.excalidraw
VOLUME /data

# Entrypoint starts both servers
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]
