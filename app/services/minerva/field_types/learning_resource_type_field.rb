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
    class LearningResourceTypeField < Base
      def to_sql(clause, _ops = {})
        unique_field = generate_uniq_field
        query =
          if null_check(clause)
            null_clause(clause)
          else
            clause.value = clause.value.split(',')
            "#{clause.operator == '<>' ? 'NOT ' : ''}(#{query_field} IN (:#{unique_field}))"
          end
        SqlResult.new(sql: query, sql_params: { unique_field.to_sym => clause.value }, tsv_column: tsv_column, value: clause.value)
      end
    end
  end
end
