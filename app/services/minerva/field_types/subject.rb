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
    class Subject < Base
      def to_sql(clause, _ops = {})
        query =
          if null_check(clause)
            null_clause(clause)
          else
            ids = if clause.operator == 'ILIKE'
              Minerva::Subject.where("name::text ILIKE ?", clause.value).pluck(:id).join(',')
            else
              Minerva::Subject.where(name: clause.value).pluck(:id).join(',')
            end
            ids.present? ? "(all_subject_ids && ARRAY[#{ids}])" : "1=0"
          end
        SqlResult.new(sql: query)
      end
    end
  end
end
