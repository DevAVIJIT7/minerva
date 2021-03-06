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

require_relative 'base'

module Minerva
  module FieldTypes
    class TypicalAgeRange < Base
      def to_sql(clause, ops = {})
        query =
            if null_check(clause)
              if clause.operator == '<>'
                "min_age IS NOT NULL OR max_age IS NOT NULL"
              else
                "min_age IS NULL AND max_age IS NULL"
              end
            else
              values = clause.value.split('-').map(&:to_i)
              "(resources.min_age <= #{values.max} AND resources.max_age >= #{values.min})".squish
            end
        SqlResult.new(sql: query)
      end

    end
  end
end