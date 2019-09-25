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
        is_null_check = null_check(clause)
        query = if filter_field == 'learningObjectives'
                  if is_null_check
                    "#{clause.operator == '<>' ? '' : 'NOT'}(EXISTS(SELECT 1 FROM alignments WHERE alignments.resource_id = resources.id))"
                  else
                    '1=0'
                  end
                elsif filter_field == 'learningObjectives.caseItemUri'
                  prepare_value(clause)
                  if is_null_check
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id)
                  else
                    query_str = clause.value
                    clause.value = Alignments::Taxonomy.where("(source ~* (?))", query_str).pluck(:id)
                    if clause.value.blank?
                      guids = query_str.split('|').map {|x| x.split('/').last}.join('|')
                      clause.value = Alignments::Taxonomy.where("(opensalt_identifier ~* (?))", guids).pluck(:id)
                    end
                  end
                  check_standard_ids(clause, is_null_check, ops)
                elsif filter_field == 'learningObjectives.targetName'
                  clause.value = clause.value.delete('%')
                  if is_null_check
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id)
                  else
                    identifiers = clause.value.downcase.split(',')
                    if Minerva.configuration.search_by_taxonomy_aliases
                      clause.value = Alignments::Taxonomy.where("(aliases && Array[:idents] OR lower(identifier) IN (:idents))", idents: identifiers).pluck(:id)
                    else
                      clause.value = Alignments::Taxonomy.where("(lower(identifier) IN (?))", identifiers).pluck(:id)
                    end

                  end
                  check_standard_ids(clause, is_null_check, ops)
                elsif filter_field == 'learningObjectives.id'
                  ids = clause.value.downcase.split(',').map(&:to_i) # just to be sure we have int array
                  clause.value = ids
                  check_standard_ids(clause, is_null_check, ops)
                elsif filter_field == 'learningObjectives.targetDescription'
                  if is_null_check
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id)
                  else
                    clause.value = Alignments::Taxonomy.where("(description ilike ?)", "%#{clause.value}%").pluck(:id)
                  end
                  check_standard_ids(clause, is_null_check, ops)
                elsif filter_field == 'learningObjectives.alignmentType'
                  prepare_value(clause)
                  if is_null_check
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id)
                  else
                    clause.value = Alignments::Taxonomy.where("(alignment_type = (?))", clause.value).pluck(:id)
                  end
                  check_standard_ids(clause, is_null_check, ops)
                elsif filter_field == 'learningObjectives.caseItemGUID'
                  prepare_value(clause)
                  if is_null_check
                    clause.value = Alignments::Taxonomy.where(null_clause(clause)).pluck(:id)
                  else
                    clause.value = Alignments::Taxonomy.where("(opensalt_identifier ~* (?))", clause.value).pluck(:id)
                  end
                  check_standard_ids(clause, is_null_check, ops)
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

      def check_standard_ids(clause, null_check, ops)
        return '1=0' if clause.value.blank?
        expr = clause.value.map {|i| "/#{i}/|^#{i}/|^.*/#{i}$|^#{i}$"}.join('|')
        ids = (Alignments::Taxonomy.where("ancestry ~ '#{expr}'").pluck(:id) + clause.value).uniq.join(',')
        if null_check
          "(resources.#{ops[:expand_objectives]&.to_bool ? 'all_taxonomy_ids' : 'direct_taxonomy_ids'} && ARRAY[#{ids}])"
        else
          "#{clause.operator == '<>' ? 'NOT' : ''}(resources.#{ops[:expand_objectives]&.to_bool ? 'all_taxonomy_ids' : 'direct_taxonomy_ids'} && ARRAY[#{ids}])"
        end
      end
    end
  end
end
