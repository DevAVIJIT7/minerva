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
  class ApplicationController < ActionController::API
    attr_accessor :resource_owner_id
    include ExceptionHandler

    before_action :authorize

    private

    def access_token
      ActionController::HttpAuthentication::Token.token_and_options(request)&.first
    end

    def authorize
      Minerva.configuration.authorizer.call(self)
    end
  end
end
