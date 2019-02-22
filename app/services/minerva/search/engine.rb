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

      RELEVANCE = 'relevance'

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

        0.upto(fields.length - 1) do |i|
          if fields[i].include?(RELEVANCE)
            tsv_columns = tf[:filter_items]&.select(&:tsv_column)&.map(&:tsv_column)&.join(' || ')
            tsv_vals = tf[:filter_items]&.select(&:tsv_column)&.map(&:value)&.join(' ')
            if tsv_columns.present? && tsv_vals.present?
              fields[i] = "LEAST(1, ts_rank_cd(#{tsv_columns}, plainto_tsquery(#{ActiveRecord::Base.connection.quote(tsv_vals)}))) AS #{RELEVANCE}"
            end
          end
        end

        if fields.is_a?(Array)
          self.fields = self.fields.join(',')
        end

        resources = Resource.select("#{fields}").where(tf[:where])
        resources = sort_resources(resources, tf)
        global_filter = Minerva.configuration.filter_sql_proc.call(resource_owner_id) if Minerva.configuration.filter_sql_proc
        resources = resources.where(global_filter) if global_filter
        cnt_query = Resource.where(tf[:where])
        total_count = (global_filter ? cnt_query.where(global_filter) : cnt_query).count

        result = PaginationService.new(resources, total_count).page(limit, offset)
        result.warning = warning

        result

      rescue Parslet::ParseFailed
        raise Errors::LtiSearchError.new(CodeMajor: :failure, Severity: :error, CodeMinor: :invalid_data,
                                         Description: 'Wrong filter parameter')
      end

      private

      def sort_resources(resources, tf)
        if sort[:json_key]
          raise ArgumentError.new("Unspecified field type for json sorting") if sort[:sort_field].field_type.blank?
          resources = resources.order("(#{sort[:sort_field].query_field}->>'#{sort[:json_key]}')::#{sort[:sort_field].field_type} #{order_by} NULLS LAST")
        else
          tsv_columns = tf[:filter_items]&.select(&:tsv_column)&.map(&:tsv_column)&.join(' || ')
          tsv_vals = tf[:filter_items]&.select(&:tsv_column)&.map(&:value)&.join(' ')
          sort_sql = sort[:sort_field].query_field
          if sort[:sort_field].query_field == RELEVANCE
            if tsv_columns.present? && tsv_vals.present?
              sort_sql = "ts_rank_cd(#{tsv_columns}, plainto_tsquery(#{ActiveRecord::Base.connection.quote(tsv_vals)}))"
            end
            sort_by_id = ", id desc"
          end
          resources = resources.order("#{sort_sql} #{order_by} NULLS LAST#{sort_by_id}")
        end
        resources
      end

      def transform(filter, ctx)
        return { where: '' } if filter.blank?
        clause_string = ''
        clause_values   = {}
        filter_items = []
        query_parse     = Search::Parser.new.parse(filter)
        query_transform = [Search::QueryTransformer.new.apply(query_parse, ctx)].flatten
        query_transform.each do |el|
          clause_string += el.sql
          clause_values.merge!(el.sql_params)
          filter_items << el
        end

        { where: [clause_string, clause_values], filter_items: filter_items }
      end

      def check_value(value, default, max)
        return default if (value <= 0) || (value > max)
        value
      end
    end
  end
end
