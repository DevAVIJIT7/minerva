# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)
require 'minerva'

module Dummy
  class Application < Rails::Application
  end
end
