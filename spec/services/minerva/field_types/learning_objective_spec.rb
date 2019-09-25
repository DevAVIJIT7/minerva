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


    let(:case_item_guid_f) { FieldTypes::LearningObjective.new('learningObjectives.caseItemGUID', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.opensalt_identifier') }
    let(:alignment_type_f) { FieldTypes::LearningObjective.new('learningObjectives.alignmentType', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description') }
    let(:target_desc_f) { FieldTypes::LearningObjective.new('learningObjectives.targetDescription', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description') }
    let(:target_url_f) { FieldTypes::LearningObjective.new('learningObjectives.targetURL', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: nil) }
    let(:ed_framework_f) { FieldTypes::LearningObjective.new('learningObjectives.educationalFramework', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: nil) }
    let(:case_item_uri_f) { FieldTypes::LearningObjective.new('learningObjectives.caseItemUri', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.source') }
    let!(:tax1) { FactoryBot.create(:taxonomy, identifier: 'some_ident1')}
    let!(:tax2) { FactoryBot.create(:taxonomy, identifier: 'some_ident2')}

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
        include_examples 'learning_objectives_null_check' do
          let(:field) { :identifier }
        end

        it 'returns sql, operator =' do
          [{alias_search: false}, {alias_search: true}].each do |variant|
            Minerva.configuration.search_by_taxonomy_aliases = variant[:alias_search]
            result = target.to_sql(OpenStruct.new(value: 'some_ident1', operator: '='))
            expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        it 'returns sql, operator <>' do
          [{alias_search: false}, {alias_search: true}].each do |variant|
            Minerva.configuration.search_by_taxonomy_aliases = variant[:alias_search]
            result = target.to_sql(OpenStruct.new(value: 'some_ident1', operator: '<>'))
            expect(result.sql).to eq("NOT(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end
        end

        include_examples 'learning_objectives_expand_objectives' do
          let(:value) { 'some_ident1' }
        end
      end
    end

    context 'learningObjectives.caseItemUri' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.source' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.caseItemUri', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.source') }

        include_examples 'learning_objectives_null_check' do
          let(:field) { :source }
        end


        context 'for other operators' do
          before do
            tax1.update(source: 'https://example.com/tax1_uri')
            tax2.update(source: 'https://example.com/tax2_uri')
          end
          it 'returns sql, operator =' do
            result = target.to_sql(OpenStruct.new(value: 'https://example.com/tax1_uri', operator: '='))
            expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator =, multiple URIs' do
            result = target.to_sql(OpenStruct.new(value: 'https://example.com/tax1_uri,https://example.com/tax2_uri', operator: '='))
            expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{tax1.id},#{tax2.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            result = target.to_sql(OpenStruct.new(value: 'https://example.com/tax1_uri', operator: '<>'))
            expect(result.sql).to eq("NOT(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          include_examples 'learning_objectives_expand_objectives' do
            let(:value) { 'https://example.com/tax1_uri' }
          end
        end

      end
    end

    context 'learningObjectives.targetDescription' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.description' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.targetDescription', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description') }

        include_examples 'learning_objectives_null_check' do
          let(:field) { :description }
        end

        context 'for other operators' do
          before do
            tax1.update(description: 'some_description1')
            tax2.update(description: 'some_description2')
          end

          it 'returns sql, operator =' do
            result = target.to_sql(OpenStruct.new(value: 'some_description', operator: '='))
            expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{tax1.id},#{tax2.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            result = target.to_sql(OpenStruct.new(value: 'some_description', operator: '<>'))
            expect(result.sql).to eq("NOT(resources.direct_taxonomy_ids && ARRAY[#{tax1.id},#{tax2.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          include_examples 'learning_objectives_expand_objectives' do
            let(:value) { 'some_description' }
          end
        end

      end
    end

    context 'learningObjectives.alignmentType' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.alignment_type' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.alignmentType', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.alignment_type') }

        include_examples 'learning_objectives_null_check' do
          let(:field) { :alignment_type }
        end

        context 'for other operators' do
          before do
            tax1.update(alignment_type: 'some_type1')
            tax2.update(alignment_type: 'some_type2')
          end

          it 'returns sql, operator =' do
            result = target.to_sql(OpenStruct.new(value: 'some_type1', operator: '='))
            expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            result = target.to_sql(OpenStruct.new(value: 'some_type1', operator: '<>'))
            expect(result.sql).to eq("NOT(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end
        end
      end
    end

    context 'learningObjectives.caseItemGUID' do
      describe '#to_sql' do
        let(:field) { 'taxonomies.opensalt_identifier' }
        let(:target) { FieldTypes::LearningObjective.new('learningObjectives.caseItemGUID', TAXONOMIES_SELECT, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.opensalt_identifier') }

        include_examples 'learning_objectives_null_check' do
          let(:field) { :opensalt_identifier }
        end

        context 'for other operators' do
          before do
            tax1.update(opensalt_identifier: 'opensalt_identifier1')
            tax2.update(opensalt_identifier: 'opensalt_identifier2')
          end

          it 'returns sql, operator =' do
            result = target.to_sql(OpenStruct.new(value: 'opensalt_identifier1', operator: '='))
            expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
            expect(result.sql_params.keys.count).to eq(0)
          end

          it 'returns sql, operator <>' do
            result = target.to_sql(OpenStruct.new(value: 'opensalt_identifier1', operator: '<>'))
            expect(result.sql).to eq("NOT(resources.direct_taxonomy_ids && ARRAY[#{tax1.id}])")
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
