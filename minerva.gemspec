# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'minerva/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'minerva'
  s.version     = Minerva::VERSION
  s.authors     = ['ACT Inc.']
  s.email       = ['ya.petrov.evgeniy@gmail.com']
  s.summary     = 'Resource search engine'
  s.license     = 'Apache'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'active_model_serializers'
  s.add_dependency 'ancestry'
  s.add_dependency 'chronic_duration'
  s.add_dependency 'faraday'
  s.add_dependency 'hairtrigger'
  s.add_dependency 'kaminari'
  s.add_dependency 'parslet'
  s.add_dependency 'pg', '~> 1.1.4'
  s.add_dependency 'rails', '~> 5.2.2.1'
  s.add_dependency 'virtus'
  s.add_dependency 'mini_magick', '>= 4.9.4'
  s.add_dependency 'carrierwave-aws'
  s.add_dependency 'carrierwave', '~> 1.2.3'
  s.add_dependency 'swagger_ui_engine'
  s.add_dependency 'rails_admin', '~> 1.4.2'
  s.add_dependency 'google-api-client', '~> 0.24.3'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'listen'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rails-erd'
  s.add_development_dependency 'rspec-rails'
end
