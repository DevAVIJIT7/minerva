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

require 'rails_helper'

module Minerva
  describe FieldTypes::LearningObjective do

    TAXONOMIES_SELECT = "(select json_agg(json_build_object('id', taxonomies.id, 'opensalt_identifier', COALESCE(taxonomies.opensalt_identifier, ''), 'description', COALESCE(taxonomies.description, ''), 'alignment_type', COALESCE(taxonomies.alignment_type, ''), 'source', COALESCE(taxonomies.source, ''), 'identifier', COALESCE(taxonomies.identifier, ''))) FROM taxonomies WHERE id = ANY(resources.all_taxonomy_ids))"

    class Taxonomy
      def self.where(*args); end
    end

    let(:taxonomy_pluck) { double(pluck: [1, 2, 3]) }
    let(:case_item_guid_f) { FieldTypes::LearningObjective.new('learningObjectives.caseItemGUID', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.opensalt_identifier') }
    let(:alignment_type_f) { FieldTypes::LearningObjective.new('learningObjectives.alignmentType', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description') }
    let(:target_desc_f) { FieldTypes::LearningObjective.new('learningObjectives.targetDescription', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description') }
    let(:target_url_f) { FieldTypes::LearningObjective.new('learningObjectives.targetURL', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: nil) }
    let(:ed_framework_f) { FieldTypes::LearningObjective.new('learningObjectives.educationalFramework', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: nil) }
    let(:case_item_uri_f) { FieldTypes::LearningObjective.new('learningObjectives.caseItemUri', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.source') }
    let(:exists_sql) { '(resources.direct_taxonomy_ids && ARRAY[1,2,3])' }

    context 'learningObjectives' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.identifier' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives', TAXONOMIES_SELECT, :learningObjectives, query_field: 'taxonomies.identifier', as_option: :learning_objectives) }

        context 'null check' do
          it 'checks presence of efficacy ' do
            result = target.to_sql(double(value: 'NULL', operator: '='))
            expect(result.sql).to eq('NOT(EXISTS(SELECT 1 FROM alignments WHERE alignments.resource_id = resources.id))')
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'checks absence of efficacy ' do
            result = target.to_sql(double(value: 'NULL', operator: '<>'))
            expect(result.sql).to eq('(EXISTS(SELECT 1 FROM alignments WHERE alignments.resource_id = resources.id))')
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        context 'for other operators' do
          it 'returns 1=0  in sql' do
            result = target.to_sql(double(value: '10', operator: '='))
            expect(result.sql).to eq('1=0')
            expect(result.sql_params.keys.count).to eq(0)
          end
        end
      end
    end

    context 'learningObjectives.targetName' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.identifier' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.targetName', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.identifier') }

        include_examples 'learning_objectives_null_check'

        it 'returns sql, operator =' do
          [{alias_search: false, valid_sql: '(lower(identifier) IN (?))'}, {alias_search: true, valid_sql: '(aliases && Array[?])'}].each do |variant|
            Minerva.configuration.search_by_taxonomy_aliases = variant[:alias_search]
            expect(Alignments::Taxonomy).to receive(:where).with(variant[:valid_sql], ['some_ident']).and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_ident', operator: '='))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        it 'returns sql, operator <>' do
          [{alias_search: false, valid_sql: 'NOT(lower(identifier) IN (?))'}, {alias_search: true, valid_sql: 'NOT(aliases && Array[?])'}].each do |variant|
            Minerva.configuration.search_by_taxonomy_aliases = variant[:alias_search]
            expect(Alignments::Taxonomy).to receive(:where).with(variant[:valid_sql], ['some_ident']).and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_ident', operator: '<>'))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        include_examples 'learning_objectives_expand_objectives' do
          Minerva.configuration.search_by_taxonomy_aliases = false
          let(:where_clause) { '(lower(identifier) IN (?))' }
          let(:value) { ['some_ident'] }
          let(:value2) { 'some_ident' }
        end

        include_examples 'learning_objectives_expand_objectives' do
          Minerva.configuration.search_by_taxonomy_aliases = true
          let(:where_clause) { '(aliases && Array[?])' }
          let(:value) { ['some_ident'] }
          let(:value2) { 'some_ident' }
        end
      end
    end

    context 'learningObjectives.caseItemUri' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.source' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.caseItemUri', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.source') }

        include_examples 'learning_objectives_null_check'

        context 'for other operators' do
          it 'returns sql, operator =' do
            expect(Alignments::Taxonomy).to receive(:where).with('(source ~* (?))', 'some_source').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_source', operator: '='))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            expect(Alignments::Taxonomy).to receive(:where).with('NOT(source ~* (?))', 'some_source').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_source', operator: '<>'))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        include_examples 'learning_objectives_expand_objectives' do
          let(:where_clause) { '(source ~* (?))' }
          let(:value) { 'some_source' }
        end
      end
    end

    context 'learningObjectives.targetDescription' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.description' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.targetDescription', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description') }

        include_examples 'learning_objectives_null_check'

        context 'for other operators' do
          it 'returns sql, operator =' do
            expect(Alignments::Taxonomy).to receive(:where).with('(description ilike ?)', '%some_description%').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_description', operator: '='))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            expect(Alignments::Taxonomy).to receive(:where).with('NOT(description ilike ?)', '%some_description%').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_description', operator: '<>'))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        include_examples 'learning_objectives_expand_objectives' do
          let(:where_clause) { '(description ilike ?)' }
          let(:value) { '%some_description%' }
          let(:value2) { 'some_description' }
        end
      end
    end

    context 'learningObjectives.alignmentType' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.alignment_type' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.alignmentType', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.alignment_type') }

        include_examples 'learning_objectives_null_check'

        context 'for other operators' do
          it 'returns sql, operator =' do
            expect(Alignments::Taxonomy).to receive(:where).with('(alignment_type = (?))', 'some_type').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_type', operator: '='))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            expect(Alignments::Taxonomy).to receive(:where).with('(alignment_type <> (?))', 'some_type').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_type', operator: '<>'))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end
        end
      end
    end

    context 'learningObjectives.caseItemGUID' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.opensalt_identifier' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.caseItemGUID', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.opensalt_identifier') }

        include_examples 'learning_objectives_null_check'

        context 'for other operators' do
          it 'returns sql, operator =' do
            expect(Alignments::Taxonomy).to receive(:where).with('(opensalt_identifier ~* (?))', 'some_guid').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_guid', operator: '='))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            expect(Alignments::Taxonomy).to receive(:where).with('NOT(opensalt_identifier ~* (?))', 'some_guid').and_return(taxonomy_pluck)
            result = target.to_sql(OpenStruct.new(value: 'some_guid', operator: '<>'))
            expect(result.sql).to eq(exists_sql)
            expect(result.sql_params.keys.count).to eq(0)
          end
        end
      end
    end

    context 'learningObjectives.educationalFramework,learningObjectives.targetURL' do
      describe '#to_sql' do
        it 'returns 1=0' do
          %w[learningObjectives.educationalFramework learningObjectives.targetURL].each do |target_field|
            target = FieldTypes::LearningObjective.new(target_field, TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: nil)
            result = target.to_sql(OpenStruct.new(value: 'some_guid', operator: '<>'))
            expect(result.sql).to eq('1=0')
          end
        end
      end
    end
  end
end
