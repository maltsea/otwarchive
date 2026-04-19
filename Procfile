# Procfile for Heroku-style deployment
web: bundle exec rails server -p $PORT
worker: bundle exec rake resque:work
scheduler: bundle exec rake resque:scheduler