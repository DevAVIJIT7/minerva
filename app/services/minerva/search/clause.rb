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
  module Search
    class Clause
      attr_accessor :operator, :field, :value, :unique_field, :cond_operator,
                    :lparen, :rparen, :ops

      def initialize(clause, ops)
        sanitizer          = Sanitize.new(field: clause[:field].first[:term], operator: clause[:field].last[:operator], value: clause[:phrase].last[:term], cond_operator: clause[:cond_operator])
        self.operator      = sanitizer.operator
        self.field         = sanitizer.field
        self.value         = sanitizer.value
        self.cond_operator = sanitizer.cond_operator if sanitizer.try(:cond_operator).present?
        self.lparen        = clause[:lparen].present? ? clause[:lparen].to_s : ''
        self.rparen        = clause[:rparen].present? ? clause[:rparen].to_s : ''
        self.ops = ops
      end

      def to_sql
        sql_result = field.to_sql(self, ops)

        FieldTypes::SqlResult.new(sql: " #{cond_operator} #{lparen} (#{sql_result.sql}) #{rparen}", sql_params: sql_result.sql_params, joins: sql_result.joins)
      end
    end
  end
end
