# frozen_string_literal: true

# Copyright 2018 ACT, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#         limitations under the License.

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment', __dir__)
require 'rspec/rails'
require_relative 'spec_helper'
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/factories/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  Dir["#{File.dirname(__FILE__)}/shared/**/*.rb"].each { |f| require f }
  config.include Testing::ResponseHelper
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
