
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
# FROM node:20.14.0

# # Add these lines
# RUN apt-get update && apt-get install -y \
#     build-essential \
#     python3 \
#     make \
#     g++ \
#     && rm -rf /var/lib/apt/lists/*

# WORKDIR /app
# COPY package*.json ./
# RUN npm install
# COPY . .
# CMD ["npm", "start"]
FROM node:20.14.0

# Install build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm install --build-from-source
COPY . .
CMD ["npm", "start"]


