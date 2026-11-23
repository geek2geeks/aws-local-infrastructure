FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies from the committed lockfile
RUN npm ci

# Copy source code
COPY src/ ./src/

# Expose API Gateway port
EXPOSE 8080

# Start the service
CMD ["node", "src/server.js"]