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

module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid do |ex|
      render status: :unprocessable_entity, json: ex.record.errors
    end

    rescue_from ActionController::ParameterMissing do |ex|
      render status: :unprocessable_entity,
             json: { message: 'ParameterMissing', errors: ex.message }
    end

    rescue_from ArgumentError do |ex|
      render status: :unprocessable_entity,
             json: { message: 'WrongArgument', errors: ex.message }
    end

    rescue_from Minerva::Errors::ForbiddenError do |ex|
      render status: :forbidden,
             json: { message: 'Forbidden', errors: ex.message }
    end

    rescue_from ActiveRecord::RecordNotFound do |ex|
      render status: :not_found, json: { error: ex.message }
    end

    rescue_from ActiveRecord::RecordNotUnique do |ex|
      render status: :unprocessable_entity,
             json: { message: 'Record not unique', errors: ex.message }
    end
  end
end
