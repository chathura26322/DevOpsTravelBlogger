# Use node image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy all files
COPY . .

# Build the Vite app
RUN npm run build

# Expose port 5173
EXPOSE 5173

# Start the app
CMD ["npm", "run", "dev"]

# FROM node:18-alpine
# WORKDIR /app
# COPY package*.json ./
# RUN npm install
# COPY . .
# RUN npm run build
# EXPOSE 5173
# CMD ["npm", "run", "dev"]