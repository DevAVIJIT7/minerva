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
  describe FieldTypes::IntArray do
    let(:field) { 'resources.some_array' }
    let(:target_array) do
      FieldTypes::IntArray.new('features', field, :features)
    end

    describe '#to_sql' do
      let(:clause_equal) do
        OpenStruct.new({ value: '10', operator: '=' })
      end

      let(:clause_unequal) do
        OpenStruct.new({ value: '10', operator: '<>' })
      end

      include_examples 'null_array_check'

      context "when the operator is '='" do
        it 'checks if the array is present and contains the value' do
          result = target_array.to_sql(clause_equal)
          expect(result.sql).to match(/\(#{field} && ARRAY\[:resources_some_array_\d+\]::int\[\]\)/)
          expect(result.sql_params.keys.count).to eq(1)
          expect(result.sql_params.values.first).to eq('10')
        end
      end

      context "when the operator is '<>'" do
        it 'checks if the array is present but does containt the value' do
          result = target_array.to_sql(clause_unequal)
          expect(result.sql).to match(/NOT\(#{field} && ARRAY\[:resources_some_array_\d+\]::int\[\]\)/)
          expect(result.sql_params.keys.count).to eq(1)
          expect(result.sql_params.values.first).to eq('10')
        end
      end
    end
  end
end
