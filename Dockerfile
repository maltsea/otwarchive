# Use Ruby 3.4.6 as base image
FROM ruby:3.4.6-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips \
    pkg-config \
    git \
    curl \
    ca-certificates \
    gnupg \
    default-mysql-client \
    shared-mime-info \
    zip \
    unzip \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 24 from NodeSource
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler -v 2.6.9

# Copy Gemfile and Gemfile.lock first for better caching
COPY Gemfile* ./

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