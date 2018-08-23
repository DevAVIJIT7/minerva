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

module SortingExamples
  shared_examples 'sorting_examples' do
    let(:sortable_fields) do
      Minerva::Search::FieldMap.instance.field_map.values.select(&:is_sortable).map do |field|
        [field.query_field.split('.').last, field.filter_field]
      end
    end

    let(:resource2) { FactoryBot.create(:video) }

    context "when orderBy is set to 'asc'" do
      it 'sorts in ascending order' do
        sortable_fields.each do |field, lti_field|
          params.merge!(sort: lti_field, orderBy: 'asc')

          resource.send(field + '=', '2')
          resource.send(field + '=', Time.current) unless resource.send(field)
          resource.save(validate: false)
          resource2.send(field + '=', '1')
          resource2.send(field + '=', 1.day.ago) unless resource2.send(field)
          resource2.save(validate: false)

          action.call

          fields = json_response['resources'].map { |el| el[lti_field] }
          expect(fields).to eq(fields.sort)
        end
      end
    end

    context "when orderBY is set to 'desc'" do
      it 'sorts in descending order' do
        sortable_fields.each do |field, lti_field|
          params.merge!(sort: lti_field, orderBy: 'desc')

          resource.send(field + '=', '1')
          resource.send(field + '=', 1.day.ago) unless resource.send(field)
          resource.save(validate: false)
          resource2.send(field + '=', '2')
          resource2.send(field + '=', Time.current) unless resource2.send(field)
          resource2.save(validate: false)

          action.call

          fields = json_response['resources'].map { |el| el[lti_field] }
          expect(fields).to eq(fields.sort.reverse)
        end
      end
    end
  end
end
