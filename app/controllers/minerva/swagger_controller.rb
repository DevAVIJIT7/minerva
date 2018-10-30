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

module Minerva
  class SwaggerController < ApplicationController

    def index
      template = ERB.new File.new(File.join(File.dirname(__FILE__), "../../../config/swagger.yaml")).read
      send_data template.result, filename: 'swagger.yaml', type: 'application/x-yaml', disposition: "attachment"
    end

  end
end