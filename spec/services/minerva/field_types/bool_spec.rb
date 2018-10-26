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
  describe FieldTypes::Bool do
    let(:field) { 'resources.embeddable' }
    let(:target) do
      FieldTypes::Bool.new('embeddable', field, :embeddable, embeddable: true)
    end

    describe '#to_sql' do
      include_examples 'null_check'

      context "operator is '='" do
        it 'checks equality' do
          result = target.to_sql(double(value: 'true', operator: '='))
          expect(result.sql).to match(/resources.embeddable = :resources_embeddable_\d+/)
          expect(result.sql_params.keys.count).to eq(1)
          expect(result.sql_params.values.first).to be true
        end
      end

    end
  end
end
