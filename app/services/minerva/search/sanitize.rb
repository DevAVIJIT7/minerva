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
    class Sanitize
      attr_accessor :fields, :sort, :order_by, :field, :operator, :value, :cond_operator, :unique_field, :has_fields, :warning

      def initialize(attrs)
        check_empty_fields(attrs)

        field = check_filter_field(attrs)

        operator = check_operator(attrs)

        result = check_selection_field(attrs)
        fields = result[:fields]
        has_fields = result.fetch(:has_fields, false)
        warning = result[:warning]

        result = check_sort(attrs)
        sort = result.slice(:sort_field, :json_key)
        warning ||= result[:warning]

        result = check_order(attrs)
        attrs[:order_by] = order_by = result[:order_by]
        warning ||= result[:warning]

        self.fields        = fields || all_sql_fields
        self.sort          = sort                                  if sort.present?
        self.order_by      = order_by                              if order_by.present?
        self.field         = field                                 if field.present?
        self.operator      = operator                              if operator.present?
        self.value         = values(attrs[:value].to_s, operator)  if attrs[:value].present?
        self.cond_operator = operators[attrs[:cond_operator].to_s] if attrs[:cond_operator].present?
        self.has_fields    = has_fields
        self.warning = warning || {}
      end

      def self.transform_fields(names)
        return unless names
        keys = FieldMap.new.map.keys
        names = names.split(',')
        return if (names - keys).any?
        names.select { |name| keys.include?(name) }.flatten.uniq
      end

      private

      def all_sql_fields
        ['resources.id'] + FieldMap.instance.field_map.values.map(&:select_sql).flatten.compact.uniq
      end

      def valid_fields
        FieldMap.instance.field_map.values.select(&:output_field).index_by(&:output_field).compact
      end

      def operators
        {
          '=' => '=',
          '!=' => '<>',
          '>=' => '>=',
          '>'  => '>',
          '<'  => '<',
          '<=' => '<=',
          '~'  => 'ILIKE',
          '&&' => 'AND',
          '||' => 'OR',
          'AND' => 'AND',
          'OR' => 'OR'
        }
      end

      def values(value, operator)
        return "%#{value}%" if operator == 'ILIKE'
        value
      end

      def check_empty_fields(attrs)
        return unless attrs.key?(:fields) && !attrs[:fields].nil? && attrs[:fields].empty?

        raise Errors::LtiSearchError.new(
          CodeMajor: :failure, Severity: :error,
          CodeMinor: :invalid_blank_selection_field,
          Description: 'Please provide not empty fields parameter'
        )
      end

      def check_filter_field(attrs)
        return unless attrs[:field].present?

        valid_fields = FieldMap.instance.field_map.values.select(&:search_allowed).index_by(&:filter_field).compact
        field = valid_fields[attrs[:field].to_s]
        return field unless field.nil?

        raise Errors::LtiSearchError.new(
          CodeMajor: :failure, Severity: :error, CodeMinor: :invalid_filter_field,
          Description: "Use any of #{valid_fields.keys.join(', ')} fields in filter parameter"
        )
      end

      def check_operator(attrs)
        return unless attrs[:operator].present?
        operator = operators[attrs[:operator].to_s]
        return operator unless operator.nil?

        raise Errors::LtiSearchError.new(
          CodeMajor: :failure, Severity: :error, CodeMinor: :invalid_data,
          Description: "Use any #{operators.keys.join(', ')} as operator in filter parameter"
        )
      end

      def check_selection_field(attrs)
        result = {}

        return result unless attrs[:fields].present?

        input_fields = attrs[:fields].split(',').map(&:to_sym)
        if input_fields.all? { |k| valid_fields.keys.include?(k) }
          result[:fields] = input_fields.map { |k| valid_fields[k]&.select_sql }.flatten.compact << 'resources.id'
          result[:has_fields] = true
        else
          result[:warning] = { Severity: :warning, CodeMinor: :invalid_selection_field,
                               Description: "Use any of #{valid_fields.keys.join(', ')} for fields parameter" }
          result[:fields] = all_sql_fields
        end

        result
      end

      def check_sort(attrs)
        return {} unless attrs[:sort].present?
        sort_key, json_key = attrs[:sort].split(':')
        sort_fields = FieldMap.instance.field_map.select { |_k, v| v.is_sortable }
        sort = sort_fields[sort_key]
        unless sort
          warning = { Severity: :warning, CodeMinor: :invalid_sort_field, Description: "Use any of #{sort_fields.keys.join(', ')} for sorting parameter" }
          sort = FieldMap.instance.field_map['name']
        end

        { warning: warning, sort_field: sort, json_key: json_key }
      end

      def check_order(attrs)
        return {} unless attrs[:order_by].present?
        unless %w[asc desc].include?(attrs[:order_by].to_s)
          warning = { Severity: :warning, CodeMinor: :invalid_sort_field, Description: 'Use asc or desc for orderBy parameter' }
          attrs[:order_by] = 'asc'
        end
        order_by = attrs[:order_by].to_s

        { warning: warning, order_by: order_by }
      end
    end
  end
end
