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
      attr_accessor :search, :filter, :all_joins, :limit, :offset, :fields, :sort,
                    :order_by, :has_fields, :warning, :params

      DEFAULT_LIMIT  = 100
      DEFAULT_OFFSET = 0

      MAX_LIMIT      = 100
      MAX_OFFSET     = 100_000

      def initialize(params)
        sanitizer     = Sanitize.new(fields: params.fetch(:fields, nil), sort: params.fetch(:sort, 'name'), order_by: params.fetch(:orderBy, :asc))
        self.filter   = params.fetch(:filter, '')
        self.limit    = check_value(params[:limit].to_i, DEFAULT_LIMIT, MAX_LIMIT)
        self.offset   = check_value(params[:offset].to_i, DEFAULT_OFFSET, MAX_OFFSET)
        self.fields   = sanitizer.fields
        self.sort     = sanitizer.sort
        self.all_joins = FieldMap.instance.field_map.values.map(&:joins).flatten
        self.warning  = sanitizer.warning
        self.order_by = sanitizer.order_by if sort.present?
        self.has_fields = sanitizer.has_fields
        self.params = params
      end

      def perform
        tf = transform(filter, expand_objectives: params.fetch('extensions.expandObjectives', false))
        joins_sql = (has_fields ? tf[:joins] : all_joins).uniq.join(' ')

        resources = Resources::Resource.select(fields).joins(joins_sql).where(tf[:where])
                                       .order("#{sort.query_field} #{order_by}")

        total_count = Resources::Resource.joins(joins_sql).where(tf[:where]).count('distinct resources.id')
        result = PaginationService.new(resources, total_count).page(limit, offset)
        result.warning = warning
        result
      rescue Parslet::ParseFailed
        raise Errors::LtiSearchError.new(CodeMajor: :failure, Severity: :error, CodeMinor: :invalid_data,
                                         Description: 'Wrong filter parameter')
      end

      private

      def transform(filter, ctx)
        return { where: '', joins: [] } if filter.blank?
        clause_string = ''
        joins_string = []
        clause_values   = {}
        query_parse     = Search::Parser.new.parse(filter)
        query_transform = [Search::QueryTransformer.new.apply(query_parse, ctx)].flatten

        query_transform.each do |el|
          clause_string += el.sql
          clause_values.merge!(el.sql_params)
          joins_string << (el.joins || '')
        end

        { where: [clause_string, clause_values], joins: joins_string }
      end

      def check_value(value, default, max)
        return default if (value <= 0) || (value > max)
        value
      end
    end
  end
end
