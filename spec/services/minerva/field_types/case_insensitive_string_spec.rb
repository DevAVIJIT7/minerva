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
  describe FieldTypes::CaseInsensitiveString do
    let(:field) { 'resources.name' }
    let(:target) do
      FieldTypes::CaseInsensitiveString.new('name', field, :name, is_sortable: true)
    end

    let(:target_description_field) do
      FieldTypes::CaseInsensitiveString.new('description', 'resources.description', :description, is_sortable: true)
    end

    describe '#to_sql' do
      include_examples 'null_check'

      context "operator 'ILIKE'" do
        it 'filters using ILIKE' do
          result = target.to_sql(double(value: 'test', operator: 'ILIKE'))
          expect(result.sql).to match(/resources.name::text ILIKE :resources_name_\d+/)
          expect(result.sql_params.keys.count).to eq(1)
          expect(result.sql_params.values.first).to eq('test')
        end
      end

      context 'query_field is description' do
        context "operator is anything besides 'ILIKE'" do
          it 'filters using the first 200 characters' do
            result = target_description_field.to_sql(double(value: 'test', operator: '='))
            expect(result.sql).to match(/substring\(resources.description::text FROM 1 FOR 200\) = :resources_description_\d+/)
            expect(result.sql_params.keys.count).to eq(1)
            expect(result.sql_params.values.first).to eq('test')
          end
        end
      end

      context "operator is not 'ILIKE' and query_field is not 'description'" do
        context "operator is '<>'" do
          it 'checks not equal' do
            result = target.to_sql(double(value: 'test', operator: '<>'))
            expect(result.sql).to match(/resources.name <> :resources_name_\d+/)
            expect(result.sql_params.keys.count).to eq(1)
            expect(result.sql_params.values.first).to eq('test')
          end
        end

        context "operator is '='" do
          it 'checks equality' do
            result = target.to_sql(double(value: 'test', operator: '='))
            expect(result.sql).to match(/resources.name = :resources_name_\d+/)
            expect(result.sql_params.keys.count).to eq(1)
            expect(result.sql_params.values.first).to eq('test')
          end
        end
      end
    end
  end
end
