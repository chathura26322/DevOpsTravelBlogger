# # Use official Node.js image
# FROM node:20.14.0

# # Install build tools and python (required for bcrypt)
# RUN apt-get update && apt-get install -y \
#     build-essential \
#     python3 \
#     && rm -rf /var/lib/apt/lists/*

# # Set the working directory inside the container
# WORKDIR /app

# # Copy package.json and package-lock.json
# COPY package*.json ./

# # Force rebuild of bcrypt for the current architecture
# RUN npm install
# RUN npm rebuild bcrypt --build-from-source

# # Copy the rest of the backend files
# COPY . .

# # Expose port (make sure this matches the port in docker-compose.yml)
# EXPOSE 5000

# # Run the backend server
# CMD ["npm", "start"]

# Use official Node.js image
FROM node:20.14.0

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./



# Copy the rest of the backend files
COPY . .

# Fix bcrypt by reinstalling it inside Docker
RUN npm rebuild bcrypt --build-from-source

# Expose port 8000
EXPOSE 8000

# Run the backend server
CMD ["npm", "start"]

