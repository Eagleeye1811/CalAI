# Stage 1: Build the Flutter web app
FROM dart:stable AS build

# Install Flutter
RUN apt-get update && \
    apt-get install -y git && \
    git clone https://github.com/flutter/flutter.git /usr/local/flutter && \
    /usr/local/flutter/bin/flutter config --no-analytics && \
    /usr/local/flutter/bin/flutter doctor

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:${PATH}"

# Set working directory
WORKDIR /app

# [FIX] Copy pubspec from the 'CalAI-App' subfolder
COPY CalAI-App/pubspec.* ./
RUN flutter pub get

# [FIX] Copy the rest of the project source from the 'CalAI-App' subfolder
COPY CalAI-App/ .

# [NEW FIX] Enable web support for the project
RUN flutter create . --platforms web

# Build the web application in release mode
RUN flutter build web --release

# Stage 2: Serve the built app with Nginx
FROM nginx:alpine

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built files from the 'build' stage
COPY --from=build /app/build/web /usr/share/nginx/html