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
    class Efficacy < Base
      def to_sql(clause, _ops = {})
        exists_sql = "all_resource_stat_ids = '{}'".squish
        query =
            if null_check(clause)
              "#{clause.operator == '<>' ? 'NOT' : ''}(#{exists_sql})"
            else
              '1=1'
            end
        SqlResult.new(sql: query)
      end
    end
  end
end
