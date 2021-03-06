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
    class TextComplexity < Base
      # we support just flesch-kincaid and lexile text complexity
      TC_TYPES = %w[flesch-kincaid lexile].freeze

      def to_sql(clause, _ops = {})
        query =
          if filter_field == 'textComplexity'
            null_clause(clause) if null_check(clause)
          elsif filter_field == 'textComplexity.name'
            '1=0' if TC_TYPES.exclude?(clause.value.downcase) && clause.operator == '='
          elsif filter_field == 'textComplexity.value'
            if null_check(clause)
              null_clause(clause)
            else
              "((#{query_field}->>'flesch-kincaid')::float #{clause.operator} #{Float(clause.value)} OR "\
            "(#{query_field}->>'lexile')::float #{clause.operator} #{Float(clause.value)})"
            end
          end

        query ||= '1=1'

        SqlResult.new(sql: query)
      end
    end
  end
end
