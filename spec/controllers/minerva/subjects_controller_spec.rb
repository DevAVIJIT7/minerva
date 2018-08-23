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

require_relative '../../rails_helper'

module Minerva
  describe SubjectsController, type: :controller do
    routes { Minerva::Engine.routes }

    describe 'GET #index' do
      let(:action) do
        -> { get :index }
      end

      let!(:math) { FactoryBot.create(:subject, name: 'math') }
      let!(:alg) { FactoryBot.create(:subject, name: 'algebra', parent: math) }
      let!(:bio) { FactoryBot.create(:subject, name: 'biology') }

      let(:expected_result) do
        [
          { 'identifier' => math.id, 'name' => math.name, 'parent' => '0' },
          { 'identifier' => alg.id, 'name' => alg.name, 'parent' => math.id.to_s },
          { 'identifier' => bio.id, 'name' => bio.name, 'parent' => '0' }
        ]
      end

      it 'returns expected attributes' do
        action.call
        expect(json_response['subjects']).to match_array(expected_result)
      end
    end
  end
end
