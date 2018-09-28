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
    class LearningObjective < Base
      def to_sql(clause, ops = {})
        query = if filter_field == 'learningObjectives'
                  if null_check(clause)
                    "#{clause.operator == '<>' ? '' : 'NOT'}(EXISTS(SELECT 1 FROM alignments WHERE alignments.resource_id = resources.id))"
                  else
                    '1=0'
                  end
                elsif filter_field == 'learningObjectives.caseItemUri'
                  prepare_value(clause)
                  if null_check(clause)
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id).join(',')
                  else
                    clause.value = Alignments::Taxonomy.where("#{clause.operator == '<>' ? 'NOT' : ''}(source ~* (?))", clause.value).pluck(:id).join(',')
                  end
                  check_standard_ids(clause, ops)
                elsif filter_field == 'learningObjectives.targetName'
                  clause.value = clause.value.delete('%')
                  if null_check(clause)
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id).join(',')
                  else
                    clause.value = Alignments::Taxonomy.where("#{clause.operator == '<>' ? 'NOT' : ''}(lower(identifier) IN (?))", clause.value.downcase.split(',')).pluck(:id).join(',')
                  end
                  check_standard_ids(clause, ops)
                elsif filter_field == 'learningObjectives.targetDescription'
                  if null_check(clause)
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id).join(',')
                  else
                    clause.value = Alignments::Taxonomy.where("#{clause.operator == '<>' ? 'NOT' : ''}(description ilike ?)", "%#{clause.value}%").pluck(:id).join(',')
                  end
                  check_standard_ids(clause, ops)
                elsif filter_field == 'learningObjectives.alignmentType'
                  prepare_value(clause)
                  if null_check(clause)
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id).join(',')
                  else
                    clause.value = Alignments::Taxonomy.where("(alignment_type #{clause.operator} (?))", clause.value).pluck(:id).join(',')
                  end
                  check_standard_ids(clause, ops)
                elsif filter_field == 'learningObjectives.caseItemGUID'
                  prepare_value(clause)
                  if null_check(clause)
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id).join(',')
                  else
                    clause.value = Alignments::Taxonomy.where("#{clause.operator == '<>' ? 'NOT' : ''}(opensalt_identifier ~* (?))", clause.value).pluck(:id).join(',')
                  end
                  check_standard_ids(clause, ops)
                elsif %w[learningObjectives.educationalFramework
                         learningObjectives.targetURL]
                      .include?(filter_field) # we don't have these in db, so returning 1=0 for sql
                  '1=0'
                end
        SqlResult.new(sql: query)
      end

      def prepare_value(clause)
        clause.value = clause.value.tr(',', '|')
        clause.value = clause.value.delete('%')
      end

      def check_standard_ids(clause, ops)
        return '1=0' if clause.value.blank?
        "(resources.#{ops[:expand_objectives]&.to_bool ? 'all_taxonomy_ids' : 'direct_taxonomy_ids'} && ARRAY[#{clause.value}])"
      end
    end
  end
end
