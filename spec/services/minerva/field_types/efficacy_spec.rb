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
  describe FieldTypes::Efficacy do
    EFFICACY_SELECT = '(select json_agg(CASE WHEN resource_stats.taxonomy_ident IS NOT NULL THEN json_build_object(resource_stats.taxonomy_ident, resource_stats.effectiveness) ELSE \'{}\'::json END) from resource_stats WHERE resource_stats.resource_id = resources.id)'

    let(:field) { 'resource_stats.effectiveness' }
    let(:target) do
      FieldTypes::Efficacy.new('efficacy', EFFICACY_SELECT, :efficacy, query_field: 'resource_stats.effectiveness')
    end

    describe '#to_sql' do

      context 'null check' do
        it 'checks presence of efficacy ' do
          result = target.to_sql(double(value: 'NULL', operator: '='))
          expect(result.sql).to eq('NOT(EXISTS(SELECT 1 FROM resource_stats WHERE resource_stats.resource_id = resources.id))')
          expect(result.sql_params.keys.count).to eq(0)
        end

        it 'checks absence of efficacy ' do
          result = target.to_sql(double(value: 'NULL', operator: '<>'))
          expect(result.sql).to eq('(EXISTS(SELECT 1 FROM resource_stats WHERE resource_stats.resource_id = resources.id))')
          expect(result.sql_params.keys.count).to eq(0)
        end
      end

      context 'for other operators' do
        it 'directly filters using the operator' do
          result = target.to_sql(double(value: '10', operator: '='))
          expect(result.sql).to eq('1=1')
          expect(result.sql_params.keys.count).to eq(0)
        end
      end
    end
  end
end
