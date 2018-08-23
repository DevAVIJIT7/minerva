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
  describe FieldTypes::Duration do
    let(:field) { 'resources.time_required' }
    let(:target) do
      FieldTypes::Duration.new('timeRequired', field, :timeRequired, as_option: :time_required, is_sortable: true)
    end

    describe '#to_sql' do
      include_examples 'null_check'

      it 'filters directly for other operators' do
        %w[= <> > < >= <=].each do |op|
          result = target.to_sql(double(value: '10', operator: op))
          expect(result.sql).to eq("#{field}::integer #{op} 10")
          expect(result.sql_params.keys.count).to eq(0)
        end
      end
    end
  end
end
