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
  describe Search::Engine do
    let(:user) { FactoryBot.create :user, first_name: '', last_name: '', username: 'username1' }
    let!(:r1) { FactoryBot.create(:video, name: 'video1', description: 'description1') }
    let!(:r2) { FactoryBot.create(:video, name: 'video2', description: 'description2') }
    let!(:r3) { FactoryBot.create(:video, name: 'video3', description: 'description3') }
    let!(:r4) { FactoryBot.create(:video, name: 'video4', description: 'description4') }

    let(:subject) { FactoryBot.create :subject, name: 'MySubject1' }
    let(:r5) { FactoryBot.create(:video, name: 'video5', description: 'description5', subjects: [subject], all_subject_ids: [subject.id]) }

    describe '#search' do
      context 'with input valid params' do
        it 'can search' do
          expect(Search::Engine.new(filter: "name='video1'").perform.resources.map(&:id)).to eq([r1].map(&:id))
          expect(Search::Engine.new(filter: "description='description2'").perform.resources.map(&:id)).to eq([r2].map(&:id))

          expect(Search::Engine.new(filter: "name='video1' AND description='description1'").perform.resources.map(&:id)).to match_array([r1].map(&:id))
          expect(Search::Engine.new(filter: "name='video2' AND description='description2'").perform.resources.map(&:id)).to match_array([r2].map(&:id))
          expect(Search::Engine.new(filter: "name='video2' AND description='description1'").perform.resources.map(&:id)).to match_array([])

          expect(Search::Engine.new(filter: "name='video2' OR name='video1' AND description='description2'").perform.resources.map(&:id)).to match_array([r2].map(&:id))
          expect(Search::Engine.new(filter: "name='video2' OR name='video1' AND description='description1'").perform.resources.map(&:id)).to match_array([r1, r2].map(&:id))
          expect(Search::Engine.new(filter: "(name='video2' OR name='video1') AND description='description1'").perform.resources.map(&:id)).to match_array([r1].map(&:id))

          expect(Search::Engine.new(filter: "name='video2' OR description='description1'").perform.resources.map(&:id)).to match_array([r1, r2].map(&:id))
          expect(Search::Engine.new(filter: "name~'video' AND description~'description'").perform.resources.map(&:id)).to match_array([r1, r2, r3, r4].map(&:id))
          expect(Search::Engine.new(filter: "name~'ide'").perform.resources.map(&:id)).to match_array([r1, r2, r3, r4].map(&:id))
        end

        it 'can sort using OrderBy' do
          expect(Search::Engine.new(sort: 'name', orderBy: 'asc').perform.resources.map(&:id)).to eq([r1, r2, r3, r4].map(&:id))
          expect(Search::Engine.new(sort: 'name', orderBy: 'desc').perform.resources.map(&:id)).to eq([r4, r3, r2, r1].map(&:id))
        end

        it 'can paginate' do
          expect(Search::Engine.new(limit: 2).perform.resources.map(&:id)).to eq([r1, r2].map(&:id))
          expect(Search::Engine.new(limit: 2, offset: 2).perform.resources.map(&:id)).to eq([r3, r4].map(&:id))
        end

        it 'can select fields' do
          result = Search::Engine.new(fields: 'name,author', filter: "name='video1'").perform.resources
          expected = { 'id' => r1.id, 'name' => r1.name, 'author' => r1.author, 'learning_resource_type' => "Media/Video" }
          expect(result[0].attributes).to eq(expected)
        end

        it 'can search by subject name' do
          r5
          expect(Search::Engine.new(filter: "search='MySubject1'").perform.resources.map(&:id)).to eq([r5].map(&:id))
        end
      end

      context 'with bad input valid params' do
        let(:warning_description) do
          valid_fields =
            Search::FieldMap.instance.field_map.values.select(&:output_field)
                            .index_by(&:output_field).compact

          "Use any of #{valid_fields.keys.join(', ')} for fields parameter"
        end

        it 'throws error wrong filter' do
          expect { Search::Engine.new(filter: "something='video1'").perform.resources }.to raise_error(Errors::LtiSearchError)
        end

        it 'throws error wrong select fields' do
          expect(Search::Engine.new(fields: "something='video1'", filter: "name='video1'").perform.warning)
            .to eq(Severity: :warning, CodeMinor: :invalid_selection_field, Description: warning_description)
        end

        it 'throws error wrong sort' do
          expect(Search::Engine.new(sort: 'invalid_field', orderBy: 'asc').perform.warning)
            .to eq(:CodeMinor=>:invalid_sort_field, :Description=>"Use any of search, name, description, publisher, efficacy, avg_efficacy, learningResourceType, language, rating, publishDate, timeRequired, author, relevance for sorting parameter", :Severity=>:warning)
        end

        it 'throws error wrong orderBy' do
          expect(Search::Engine.new(sort: 'name', orderBy: 'aasc').perform.warning).to eq(Severity: :warning, CodeMinor: :invalid_sort_field, Description: 'Use asc or desc for orderBy parameter')
        end
      end
    end
  end
end
