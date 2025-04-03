# # Use official Node.js image
# FROM node:20.14.0

# # Set the working directory inside the container
# WORKDIR /app

# # Copy package.json and package-lock.json
# COPY package*.json ./



# # Copy the rest of the backend files
# COPY . .

# # Fix bcrypt by reinstalling it inside Docker
# RUN npm rebuild bcrypt --build-from-source

# # Expose port 8000
# EXPOSE 8000

# # Run the backend server
# CMD ["npm", "start"]

FROM node:20.14.0
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm rebuild bcrypt --build-from-source
EXPOSE 8000
CMD ["npm", "start"]