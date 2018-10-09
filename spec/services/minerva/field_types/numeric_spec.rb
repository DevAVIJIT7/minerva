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
  describe FieldTypes::Numeric do
    let(:field) { 'resources.rating' }
    let(:target) do
      FieldTypes::Numeric.new('rating', field, :name, is_sortable: true)
    end

    describe '#to_sql' do
      include_examples 'null_check'


      context "operator is '<>'" do
        it 'checks not equal' do
          result = target.to_sql(double(value: '123', operator: '<>'))
          expect(result.sql).to match(/resources.rating <> :resources_rating_\d+/)
          expect(result.sql_params.keys.count).to eq(1)
          expect(result.sql_params.values.first).to eq('123')
        end
      end

      context "operator is '='" do
        it 'checks equality' do
          result = target.to_sql(double(value: '123', operator: '='))
          expect(result.sql).to match(/resources.rating = :resources_rating_\d+/)
          expect(result.sql_params.keys.count).to eq(1)
          expect(result.sql_params.values.first).to eq('123')
        end
      end

    end
  end
end
