source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.1.4", ">= 8.1.4.1"
gem "pg", "~> 1.1"
gem "puma"
gem "bootsnap", require: false

gem "sprockets-rails"
gem "sprockets", ">= 4.3"


gem "bootstrap", "~> 5.3.0"
gem "dartsass-sprockets"
gem "font-awesome-sass", "~> 6.7"
gem "importmap-rails"
gem "will_paginate", "~> 3.3"
gem "will_paginate-bootstrap-style"

gem "omniauth-google-oauth2", ">= 1.2.3"
gem "omniauth-rails_csrf_protection"
gem "config"
gem "image_processing"
gem "activestorage-validator"
gem "pg_search"
gem "sidekiq"
gem "sidekiq-scheduler"

group :development, :test do
  gem "debug", platforms: [:mri]
  gem "dotenv-rails"
  gem "minitest", "~> 5.0"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
