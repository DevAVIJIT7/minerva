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
  module FieldTypes
    class Base

      attr_accessor :custom_search, :filter_field, :is_sortable, :select_sql,
                    :as_option, :query_field, :output_field, :search_allowed, :field_type,
                    :tsv_column, :is_extension

      def initialize(filter_field, select_sql, output_field, ops = {})
        self.filter_field = filter_field
        self.query_field = ops.fetch(:query_field, select_sql)
        self.select_sql = "#{select_sql} AS #{ops.fetch(:as_option, output_field)}" if select_sql.present?
        self.output_field = output_field
        self.is_sortable = ops.fetch(:is_sortable, false)
        self.search_allowed = ops.fetch(:search_allowed, true)
        self.custom_search = ops.fetch(:custom_search, false)
        self.field_type = ops.fetch(:field_type, nil)
        self.tsv_column = ops.fetch(:tsv_column, nil)
        self.is_extension = ops.fetch(:is_extension, false)
      end

      def to_sql(_clause, _ops = {})
        raise NotImplementedError
      end

      def generate_uniq_field
        "#{query_field.tr('.', '_')}_#{rand(10**10)}"
      end

      private

      def null_check(clause)
        clause.value.present? && clause.value.casecmp('null').zero?
      end

      def less_than_check(operator)
        %w[< <=].include?(operator)
      end

      def greater_than_check(operator)
        %w[> >=].include?(operator)
      end

      def null_clause(clause)
        "#{query_field} IS #{clause.operator == '<>' ? 'NOT ' : ''}NULL"
      end
    end
  end
end
