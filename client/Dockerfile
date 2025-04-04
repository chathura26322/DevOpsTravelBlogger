# # Use node image
# FROM node:18-alpine

# # Set working directory
# WORKDIR /app

# # Copy package.json and install dependencies
# COPY package*.json ./
# RUN npm install

# # Copy all files
# COPY . .

# # Build the Vite app
# RUN npm run build

# # Expose port 5173
# EXPOSE 5173

# # Start the app
# CMD ["npm", "run", "dev"]

# FROM node:18-alpine
# WORKDIR /app
# COPY package*.json ./
# RUN npm install
# COPY . .
# RUN npm run build
# EXPOSE 5173
# CMD ["npm", "run", "dev"]

# Stage 1: Build the Vite app
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve the built app
FROM node:18-alpine
WORKDIR /app
RUN npm install -g serve
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["serve", "-s", "dist", "-l", "3000"]
