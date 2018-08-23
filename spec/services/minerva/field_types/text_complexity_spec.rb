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
  describe FieldTypes::TextComplexity do
    TEXT_COMPLEXITY_SELECT = "jsonb_build_array(json_build_object('name', 'Flesch-Kincaid', 'value', resources.text_complexity->>'flesch_kincaid'), json_build_object('name', 'Lexile', 'value', resources.text_complexity->>'lexile'))"

    let(:field) { 'resources.text_complexity' }

    describe '#to_sql' do
      context 'textComplexity' do
        let(:target) { FieldTypes::TextComplexity.new('textComplexity', TEXT_COMPLEXITY_SELECT, :textComplexity, as_option: :text_complexity, query_field: 'resources.text_complexity') }

        include_examples 'null_check'

        context 'for other operators' do
          it 'directly filters using the operator' do
            result = target.to_sql(double(value: '10', operator: '='))
            expect(result.sql).to eq('1=1')
            expect(result.sql_params.keys.count).to eq(0)
          end
        end
      end

      context 'textComplexity.name' do
        let(:target) { FieldTypes::TextComplexity.new('textComplexity.name', TEXT_COMPLEXITY_SELECT, :textComplexity, as_option: :text_complexity, query_field: 'resources.text_complexity') }

        it 'filters text complexity type' do
          result = target.to_sql(double(value: 'some_text_complexity_type', operator: '='))
          expect(result.sql).to eq('1=0')
        end

        it 'returns resources with lexile type' do
          result = target.to_sql(double(value: 'lexile', operator: '='))
          expect(result.sql).to eq('1=1')
        end
      end

      context 'textComplexity.value' do
        let(:target) { FieldTypes::TextComplexity.new('textComplexity.value', TEXT_COMPLEXITY_SELECT, :textComplexity, as_option: :text_complexity, query_field: 'resources.text_complexity') }

        include_examples 'null_check'

        it 'returns resources with lexile type' do
          result = target.to_sql(double(value: '10', operator: '='))
          expect(result.sql).to eq("((resources.text_complexity->>'flesch-kincaid')::float = 10.0 OR (resources.text_complexity->>'lexile')::float = 10.0)")
        end
      end
    end
  end
end
