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
require 'parslet'

module Minerva
  module Search
    class Engine
      attr_accessor :search, :filter, :limit, :offset, :fields, :sort,
                    :order_by, :has_fields, :warning, :params, :resource_owner_id

      DEFAULT_LIMIT  = 100
      DEFAULT_OFFSET = 0

      MAX_LIMIT      = 100
      MAX_OFFSET     = 100_000

      def initialize(params, resource_owner_id = nil)
        sanitizer     = Sanitize.new(fields: params.fetch(:fields, nil), sort: params.fetch(:sort, 'name'), order_by: params.fetch(:orderBy, :asc))
        self.filter   = params.fetch(:filter, '')
        self.limit    = check_value(params[:limit].to_i, DEFAULT_LIMIT, MAX_LIMIT)
        self.offset   = check_value(params[:offset].to_i, DEFAULT_OFFSET, MAX_OFFSET)
        self.fields   = sanitizer.fields
        self.sort     = sanitizer.sort
        self.warning  = sanitizer.warning
        self.order_by = sanitizer.order_by if sort.present?
        self.has_fields = sanitizer.has_fields
        self.resource_owner_id = resource_owner_id
        self.params = params
      end

      def perform
        tf = transform(filter, expand_objectives: params.fetch('extensions.expandObjectives', false))

        if fields.is_a?(Array)
          self.fields = self.fields.join(',')
        end

        resources = Resource.select("#{fields}").where(tf[:where])
        resources, sort_warning = sort_resources(resources, tf)

        global_filter = Minerva.configuration.filter_sql_proc.call(resource_owner_id) if Minerva.configuration.filter_sql_proc
        resources = resources.where(global_filter) if global_filter
        cnt_query = Resource.where(tf[:where])
        total_count = (global_filter ? cnt_query.where(global_filter) : cnt_query).count

        result = PaginationService.new(resources, total_count).page(limit, offset)
        result.warning = warning.presence || sort_warning

        result

      rescue Parslet::ParseFailed
        raise Errors::LtiSearchError.new(CodeMajor: :failure, Severity: :error, CodeMinor: :invalid_data,
                                         Description: 'Wrong filter parameter')
      end

      private

      def sort_resources(resources, tf)
        warning = {}
        if sort[:json_key]
          raise ArgumentError.new("Unspecified field type for json sorting") if sort[:sort_field].field_type.blank?
          resources = resources.order("(#{sort[:sort_field].query_field}->>'#{sort[:json_key]}')::#{sort[:sort_field].field_type} #{order_by} NULLS LAST")
        elsif tf[:sort_override]

          resources = resources.order("#{tf[:sort_override]} #{order_by} NULLS LAST")
        else
          if sort[:sort_field].sort_name == 'relevance' && tf[:sort_override].nil?
            warning = { Severity: :warning, CodeMinor: :invalid_sort_field,
                        Description: "Use relevance for sort only if you use 'search' in filter param" }
          end
          resources = resources.order("#{sort[:sort_field].query_field} #{order_by} NULLS LAST")
        end
        [resources, warning]
      end

      def transform(filter, ctx)
        return { where: '' } if filter.blank?
        clause_string = ''
        clause_values   = {}
        sort_override = nil
        query_parse     = Search::Parser.new.parse(filter)
        query_transform = [Search::QueryTransformer.new.apply(query_parse, ctx)].flatten
        query_transform.each do |el|
          clause_string += el.sql
          clause_values.merge!(el.sql_params)
          sort_override ||= el.sort_by_sql
        end

        { where: [clause_string, clause_values], sort_override: sort_override }
      end

      def check_value(value, default, max)
        return default if (value <= 0) || (value > max)
        value
      end
    end
  end
end
