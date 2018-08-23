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
    class Search < Base
      def to_sql(clause, _ops = {})
        val = clause.value.delete('%').downcase
        sql_params = {}
        query = if null_check(clause)
                  if clause.operator == '<>'
                    'resources.tsv_text IS NOT NULL OR taxonomies.name IS NOT NULL'
                  else
                    'resources.tsv_text IS NULL AND taxonomies.name IS NULL'
                  end
                else
                  pre_params = SqlParam.from(tsv_text: val, taxonomies_name: val)
                  sql_params = SqlParam.ar_params(pre_params)
                  "#{clause.operator == '<>' ? 'NOT ' : ''}(resources.tsv_text @@ plainto_tsquery(:#{pre_params[:tsv_text][:uniq_sym]}) OR taxonomies.name = :#{pre_params[:taxonomies_name][:uniq_sym]})"
                end

        SqlResult.new(sql: query, joins: joins, sql_params: sql_params)
      end
    end
  end
end
