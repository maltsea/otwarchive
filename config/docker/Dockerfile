FROM ruby:3.4.6

# Install Node.js 20 from NodeSource
RUN mkdir -p /etc/apt/keyrings && \
    apt-get update && apt-get install -y \
    curl ca-certificates gnupg && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install additional packages
RUN apt-get update             && \
    apt-get install -y            \
        calibre                   \
        default-mysql-client      \
        libvips                   \
        shared-mime-info          \
        zip

# Clean and mount repository at /otwa
RUN rm -rf /otwa && mkdir -p /otwa
WORKDIR /otwa
VOLUME /otwa

# Install ruby packages
COPY Gemfile .
COPY Gemfile.lock .
RUN gem install bundler -v 2.6.9 && bundle install

# Default command to run in a new container
EXPOSE 3000
CMD bundle exec rails s -p 3000
