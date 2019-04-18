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
  describe FieldTypes::JSONField do
    let(:field) { "resources.opened->>'featured'" }
    let(:target) do
      FieldTypes::JSONField.new('featured', 'resources.opened', :featured)
    end

    describe '#to_sql' do
      context 'default operators' do
        include_examples 'null_check'

        it 'filters directly using the operators' do
          %w[= <> > < >= <=].each do |op|
            result = target.to_sql(double(value: '10', operator: op))
            expect(result.sql).to match(/resources.opened->>'featured' #{op} :resources_opened_\d+/)
            expect(result.sql_params.keys.count).to eq(1)
            expect(result.sql_params.values.first).to eq('10')
          end
        end
      end

      context 'when the subkey_type is text[]' do
        let(:target_array) do
          FieldTypes::JSONField.new('featured', 'resources.opened', :featured, subkey_type: 'text[]')
        end

        include_examples 'null_array_check'

        include_examples 'text_arrays' do
          let(:equal_opts) { { query_json_inner_field: '' } }
          let(:unequal_opts) { { query_json_inner_field: '' } }
          let(:var_name) { 'resources.opened' }
        end
      end
    end
  end
end
