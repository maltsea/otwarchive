# OTW Archive Deployment Guide

This guide will help you deploy the OTW Archive application to production.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- At least 10GB free disk space

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/otwcode/otwarchive.git
   cd otwarchive
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your production values
   nano .env
   ```

3. **Run the deployment script**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. **Access your application**
   - Web interface: http://localhost:3000
   - Admin interface: Configure admin user through the web interface

## Manual Deployment

If you prefer to deploy manually:

1. **Build and start services**
   ```bash
   docker compose -f docker-compose.prod.yml up -d db redis elasticsearch memcached
   sleep 60  # Wait for services to start
   ```

2. **Setup database**
   ```bash
   docker compose -f docker-compose.prod.yml run --rm web bundle exec rake db:create db:migrate
   ```

3. **Setup search indexes**
   ```bash
   docker compose -f docker-compose.prod.yml run --rm web bundle exec rake search:index
   ```

4. **Precompile assets**
   ```bash
   docker compose -f docker-compose.prod.yml run --rm web bundle exec rake assets:precompile
   ```

5. **Start the application**
   ```bash
   docker compose -f docker-compose.prod.yml up -d web worker scheduler
   ```

## Environment Configuration

### Required Environment Variables

Copy `.env.example` to `.env` and configure:

- **Database**: `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`
- **Redis**: `REDIS_URL`
- **Elasticsearch**: `ELASTICSEARCH_URL`
- **Rails**: `SECRET_KEY_BASE`, encryption keys
- **Email**: SMTP configuration for user notifications
- **AWS S3**: For file uploads (optional)
- **Archive Settings**: `ARCHIVE_NAME`, `ARCHIVE_HOST`, etc.

### Generating Secret Keys

```bash
# Generate SECRET_KEY_BASE
docker compose -f docker-compose.prod.yml run --rm web bundle exec rake secret

# Generate encryption keys (run multiple times)
openssl rand -hex 32
```

## Production Considerations

### Security
- Change all default passwords
- Use strong, unique secret keys
- Configure SSL/TLS certificates
- Set up proper firewall rules

### Performance
- Adjust `WEB_CONCURRENCY` based on your server resources
- Configure Redis and Elasticsearch memory limits
- Set up monitoring and logging

### Backups
- Regular database backups
- File system backups for uploaded content
- Configuration backups

## Deployment Platforms

### Docker Hosting Services
- **DigitalOcean App Platform**: Supports docker-compose.yml
- **Railway**: Good Docker support
- **Render**: Supports Docker with persistent disks

### Cloud Platforms
- **AWS ECS/Fargate**: Use docker-compose.prod.yml as reference
- **Google Cloud Run**: Container-based deployment
- **Azure Container Instances**: Direct Docker deployment

### Traditional Hosting
- **Heroku**: Use the provided `Procfile`
- **VPS**: Use docker-compose.prod.yml with nginx reverse proxy

## Troubleshooting

### Common Issues

1. **Database connection fails**
   - Check DB_HOST, DB_USERNAME, DB_PASSWORD in .env
   - Ensure database service is running: `docker compose -f docker-compose.prod.yml ps`

2. **Elasticsearch connection fails**
   - Wait for Elasticsearch to fully start (can take 30-60 seconds)
   - Check ELASTICSEARCH_URL in .env

3. **Assets not loading**
   - Run: `docker compose -f docker-compose.prod.yml run --rm web bundle exec rake assets:precompile`
   - Clear browser cache

4. **Permission errors**
   - Ensure Docker has proper permissions
   - Check file ownership in mounted volumes

### Logs
```bash
# View all logs
docker compose -f docker-compose.prod.yml logs -f

# View specific service logs
docker compose -f docker-compose.prod.yml logs -f web
```

### Maintenance
```bash
# Restart services
docker compose -f docker-compose.prod.yml restart

# Update application
git pull
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml run --rm web bundle exec rake db:migrate
docker compose -f docker-compose.prod.yml up -d

# Backup database
docker compose -f docker-compose.prod.yml exec db mysqldump -u root -p otwarchive_production > backup.sql
```

## Support

For issues specific to the OTW Archive codebase, please refer to:
- [OTW Archive GitHub Repository](https://github.com/otwcode/otwarchive)
- [OTW Archive Documentation](https://archiveofourown.org/faq/tutorial)

## License

This deployment configuration is provided as-is for deploying the OTW Archive application.