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
  describe FieldTypes::SearchField do
    let(:target) do
      FieldTypes::SearchField.new('search', nil, nil, query_field: 'tsv_text', custom_search: true)
    end

    describe '#to_sql' do
      context 'null check' do
        specify 'NULL' do
          result = target.to_sql(double(value: 'NULL', operator: '='))
          expect(result.sql).to eq('tsv_text IS NULL')
          expect(result.sql_params.keys.count).to eq(0)
        end

        specify 'NOT NULL' do
          result = target.to_sql(double(value: 'NULL', operator: '<>'))
          expect(result.sql).to eq('tsv_text IS NOT NULL')
          expect(result.sql_params.keys.count).to eq(0)
        end
      end

      context 'other operators, not null checks' do
        specify '=' do
          result = target.to_sql(double(value: 'something', operator: '='))
          expect(result.sql).to match(/\(resources.tsv_text @@ plainto_tsquery\('english', :tsv_text_\d+\)\)/)
          expect(result.sql_params.values.first).to eq('something')
        end

        specify '!=' do
          result = target.to_sql(double(value: 'something', operator: '<>'))
          expect(result.sql).to match(/NOT \(resources.tsv_text @@ plainto_tsquery\('english', :tsv_text_\d+\)\)/)
          expect(result.sql_params.values.first).to eq('something')
        end
      end
    end
  end
end
