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

require 'rails/generators'
require 'rails/generators/active_record'

module Minerva
  class InstallGenerator < ::Rails::Generators::Base
    include Rails::Generators::Migration
    argument :name, type: :string, default: 'random_name'
    source_root File.expand_path('templates', __dir__)

    def self.next_migration_number(_dir)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end

    def copy_files
      migration_template 'minerva_migration.rb', 'db/migrate/create_minerva_tables.rb'
      migration_template 'minerva_functions.sql', 'minerva_functions.sql'
    end

    def create_initializer_file
      init_path = "#{source_paths.first}/initializer.rb"
      create_file 'config/initializers/minerva.rb', File.read(init_path)
    end
  end
end
