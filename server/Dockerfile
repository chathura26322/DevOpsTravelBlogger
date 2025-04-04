# Use official Node.js image
FROM node:20.14.0

# Install build tools and python (required for bcrypt)
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies (including bcrypt)
RUN npm install

# Copy the rest of the backend files
COPY . .

# Expose port 8000
EXPOSE 8000

# Run the backend server
CMD ["npm", "start"]
