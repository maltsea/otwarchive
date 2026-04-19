# Use Ruby 3.4.6 as base image
FROM ruby:3.4.6-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips \
    pkg-config \
    git \
    curl \
    default-mysql-client \
    shared-mime-info \
    zip \
    unzip \
    nodejs \
    npm \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler -v 2.6.9

# Copy Gemfile and Gemfile.lock first for better caching
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle install

# Copy the rest of the application code
COPY . .

# Precompile assets (if needed for production)
# RUN bundle exec rake assets:precompile

# Expose port 3000
EXPOSE 3000

# Set environment to production (change as needed)
ENV RAILS_ENV=production

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]