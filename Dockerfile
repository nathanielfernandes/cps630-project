FROM node:21-alpine3.18

# sets the working directory of all following instructions
WORKDIR /app

# copy the package.json and package-lock.json files to /app
COPY package*.json .

# run command to install dependencies
RUN npm install 

# copy all the files in our project directory to /app
COPY . .

# pass in build-time env variables 
ARG PUBLIC_SUPABASE_URL
ARG PUBLIC_SUPABASE_ANON_KEY

# run command to build project and output to ./build
RUN npm run build

# running the index.js file located in the build folder with node
CMD ["node", "./build/index.js"]