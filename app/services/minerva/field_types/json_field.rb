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
    class JSONField < Base
      attr_accessor :subkey_type, :query_json_inner_field

      def initialize(filter_field, select_sql, output_field, ops = {})
        super

        self.subkey_type = ops[:subkey_type]
        self.query_json_inner_field = query_field + "::json->>'#{filter_field}'"
      end

      def to_sql(clause, _ops = {})
        unique_field = generate_uniq_field
        query =
          if null_check(clause)
            case subkey_type
            when 'text[]'
              "array_length(#{query_json_inner_field}, 1) IS #{clause.operator == '<>' ? 'NOT ' : ''}NULL #{clause.operator == '<>' ? 'AND' : 'OR'} " \
        "array_length(#{query_json_inner_field}, 1) #{clause.operator == '<>' ? '>' : '='} 0"
            else
              "#{query_json_inner_field} IS #{clause.operator == '<>' ? 'NOT ' : ''}NULL"
            end
          else
            case subkey_type
            when 'text[]'
              "array_length(#{query_json_inner_field}, 1) > 0 AND " \
        "#{clause.operator == '<>' ? 'NOT' : ''}(#{query_json_inner_field}::citext[] && ARRAY[:#{unique_field}]::citext[])"
            else
              "#{query_json_inner_field} #{clause.operator} :#{unique_field}"
            end
          end
        SqlResult.new(sql: query, sql_params: { unique_field.to_sym => clause.value })
      end
    end
  end
end
