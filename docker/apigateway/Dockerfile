FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src/ ./src/

# Expose API Gateway port
EXPOSE 8080

# Start the service
CMD ["node", "src/server.js"]