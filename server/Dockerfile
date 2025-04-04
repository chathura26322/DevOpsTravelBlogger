# FROM node:20.14.0

# # Install build tools
# RUN apt-get update && apt-get install -y \
#     build-essential \
#     python3 \
#     make \
#     g++ \
#     && rm -rf /var/lib/apt/lists/*

# WORKDIR /app
# COPY package*.json ./
# RUN npm install --build-from-source
# COPY . .
# CMD ["npm", "start"]

# FROM node:20.14.0

# # Install build tools and python
# RUN apt-get update && \
#     apt-get install -y build-essential python3 make g++ && \
#     rm -rf /var/lib/apt/lists/*

# WORKDIR /app

# # Copy package files first for better caching
# COPY package*.json ./

# # Install dependencies with build tools
# RUN npm install --build-from-source

# # Copy application code
# COPY . .

# # Set production environment
# ENV NODE_ENV=production

# CMD ["npm", "start"]
FROM node:20.14.0

# Install build tools and ensure python3 is linked as python for node-gyp
RUN apt-get update && \
    apt-get install -y build-essential python3 make g++ && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies, force bcrypt to build from source explicitly
RUN npm install && \
    npm rebuild bcrypt --build-from-source

# Copy application code
COPY . .

# Set production environment
ENV NODE_ENV=production

CMD ["npm", "start"]


