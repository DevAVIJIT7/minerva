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
  describe ResourcesController, type: :controller do
    routes { Minerva::Engine.routes }

    let(:params) { {} }
    let(:resource) do
      FactoryBot.create(
        :game,
        publisher: 'publisher', name: 'test',
        typical_age_range: '6-7', use_rights_url: 'http://use_rights_url.com',
        accessibility_input_methods: ['fullMouseControl'],
        access_mode: %w[orientation color textOnImage position visual]
      )
    end

    describe 'POST #create' do
      before do
        subj1 = FactoryBot.create(:subject, name: 'Mathematics')
        subj2 = FactoryBot.create(:subject, name: 'Grammar')
        t1 = FactoryBot.create(:taxonomy, opensalt_identifier: '31645878-12a7-11e8-9f72-0242ac120005')
        t2 = FactoryBot.create(:taxonomy, identifier: 'teks.math.6-8.mps.1')
      end

      it 'creates resource from params' do
        path = File.join(Rails.root, '../spec/fixtures/resources.csv')
        data = { name: 'AP / AB Calculus Test - Sample Questions 13 & 14', description: 'description',
                 url: 'https://www.youtube.com/embed/O9V2Bvysvs0', learning_resource_type: 'Media/Video', language: 'en',
                 thumbnail_url: 'https://images-staging.opened.com/pictures/1890960/image20170920-4-1ckjl84.jpg?1505872718',
                 typical_age_range: '0-12', text_complexity: { 'flesch-kincaid' => '1', 'lexile' => '2' },
                 author: '', publisher: 'patrickJMT', use_rights_url: 'some_url', time_required: 278.0, technical_format: 'text', extensions: {},
                 rating: 3.0, relevance: 0.0,
                 lti_link: { 'title' => 'https://www.opened.io/resources/1890960', 'launch_url' => 'https://www.opened.io/resources/1890960',
                             'description' => '', 'extension' => '', 'secure_launch_url' => '', 'icon' => '', 'secure_icon' => '',
                             'vendor' => { 'code' => 'NULL', 'name' => 'OpenEd' },
                             'cartridge_icon' => { 'name' => 'NULL', 'resourceUri' => 'NULL' },
                             'cartridge_bundle' => { 'name' => 'NULL', 'resourceUri' => 'NULL' } },
                 educational_audience: [], accessibility_api: [], accessibility_input_methods: ['fullMouseControl'], accessibility_features: [],
                 accessibility_hazards: [], access_mode: %w[auditory color textOnImage visual],
                 taxonomies: ['teks.math.6-8.mps.1', '31645878-12a7-11e8-9f72-0242ac120005'], subjects: ['Mathematics'] }

        post :create, params: data
        expect(json_response.count).to eq(1)

        (data.keys - %i[taxonomies subjects]).each do |k|
          expect(json_response[0][k.to_s]).to eq(data[k])
        end
        expect(json_response[0]['subjects'].count).to eq(1)
        expect(json_response[0]['taxonomies'].count).to eq(2)
      end

      it 'creates resources from csv file' do
        path = File.join(File.expand_path('..', Rails.root), 'fixtures/resources.csv')
        data = { csv_file: Rack::Test::UploadedFile.new(path) }
        post :create, params: data
        expect(json_response.count).to eq(50)
        expect(Alignments::Alignment.count).to be > 0
        expect(ResourcesSubject.count).to be > 0
      end

      it 'creates resources from csv file url' do
        path = File.join(File.expand_path('..', Rails.root), 'fixtures/resources.csv')
        allow(Faraday).to receive(:get).and_return(double(body: File.read(path)))

        data = { csv_file_url: 'http://example.com/file.csv' }
        post :create, params: data
        expect(Resources::Resource.count).to eq(50)
      end
    end

    describe 'PUT #update' do
      it 'updates resource' do
        params = { id: resource.id, name: 'New name' }
        put :update, params: params
        expect(json_response['name']).to eq(params[:name])
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes resource' do
        resource
        expect do
          delete :destroy, params: { id: resource.id }
        end.to change(Resources::Resource, :count).by(-1)
      end
    end

    describe 'GET #index' do
      let(:action) do
        lambda {
          get :index, params: params
        }
      end

      let!(:resource_stat) do
        FactoryBot.create(:resource_stat, resource: resource, effectiveness: 77)
      end

      context 'authorized user request' do
        describe 'filter' do
          context 'search operators in filter params' do
            context "when operator is '='" do
              it 'tests equality' do
                params.merge!(limit: 1, filter: "name='test'")
                action.call
                expect(json_response['resources'].map { |el| el['name'] })
                  .to eq(['test'])
              end
            end

            context "when operator is '~'" do
              context "for search term 'search'" do
                it 'tests exact match' do
                  params.merge!(limit: 1, filter: "search~'test'")
                  action.call
                  expect(json_response['resources'].map { |el| el['name'] })
                    .to eq(['test'])
                end
              end

              context 'for case-insensitive fields' do
                it 'tests similarity' do
                  params.merge!(limit: 1, filter: "name~'TeS'")
                  action.call
                  expect(json_response['resources'].map { |el| el['name'] })
                    .to eq(['test'])
                end
              end
            end
          end

          describe 'searching subject' do
            it 'returns correct subject array' do
              params[:limit] = 1
              resource.subjects << FactoryBot.create(:subject, name: 'Measurement & Data')
              resource.subjects << FactoryBot.create(:subject, name: 'Math')
              params.merge!(fields: 'subject', filter: "subject='Measurement & Data'")
              action.call
              expect(json_response['resources'][0]['subject']).to match_array(['Measurement & Data', 'Math'])
            end

            it 'returns not null subject array' do
              params[:limit] = 1
              resource.subjects << FactoryBot.create(:subject, name: 'Math')
              params.merge!(fields: 'subject', filter: "subject!='null'")
              action.call
              expect(json_response['resources'][0]['subject']).to match_array(%w[Math])
            end

            it 'allows for searching sub-name' do
              resource.subjects << FactoryBot.create(:subject, name: 'Measurement & Data')
              params.merge!(fields: 'subject', filter: "subject~'Data'")
              action.call
              expect(json_response['resources'][0]['subject']).to match_array(['Measurement & Data'])
            end
          end

          describe 'searching efficacy' do
            before(:each) do
              FactoryBot.create(:resource_stat, resource: resource)
              FactoryBot.create(:resource_stat, resource: resource)
            end

            it 'returns efficacy' do
              params.merge!(limit: 1, filter: "efficacy='NULL'")
              action.call
              expect(json_response['resources']).to be_blank

              params.merge!(limit: 1, filter: "efficacy!='NULL'")
              action.call

              stats = Alignments::ResourceStat.pluck(:taxonomy_ident, :effectiveness).map { |el| [el].to_h }
              expect(json_response['resources'][0]['efficacy']).to match_array(stats)
            end
          end

          context 'searches by learningObjectives' do
            let!(:s1) do
              s = FactoryBot.create(:taxonomy, identifier: 'CCSS.Math.Content.2.G.A.1', description: 'some math description ', opensalt_identifier: 's1')
              s.alignments = [FactoryBot.create(:alignment, resource: resource)]
              s
            end

            let!(:s2) do
              s = FactoryBot.create(:taxonomy, identifier: 'CCSS.Math.Content.2.G.A.2', opensalt_identifier: 's2', source: 'https://opensalt.net/uri/s2')
              s.alignments = [FactoryBot.create(:alignment, resource: resource)]
              s
            end

            context 'when filtering on not null' do
              it 'returns some resources with taxonomies' do
                params.merge!(limit: 1, filter: "learningObjectives!='NULL'")
                action.call

                expect(json_response['resources'].map { |el| el['name'] })
                  .to eq([resource.name])
                expect(json_response['resources'][0]['learningObjectives'].map { |el| el['targetName'] })
                  .to match_array([s1.identifier, s2.identifier])
              end
            end

            context 'when it does not match any targets' do
              it 'returns empty set' do
                params.merge!(limit: 1, filter: "learningObjectives.targetName='test'")
                action.call
                expect(json_response['resources'].count).to eq(0)
              end
            end

            context 'returns empty set for not present field in db' do
              it 'returns empty set' do
                params.merge!(limit: 1, filter: "learningObjectives.educationalFramework!='NULL'")
                action.call
                expect(json_response['resources'].count).to eq(0)
              end
            end

            context 'when it does not match any targets' do
              it 'returns empty set' do
                params.merge!(limit: 1, filter: "learningObjectives.targetDescription!='NULL'")
                action.call
                expect(json_response['resources'].count).to eq(1)
              end
            end

            context 'when filtering using learningObjectives.caseItemUri' do
              it 'returns resource' do
                params.merge!(limit: 1, filter: "learningObjectives.caseItemUri~'https://opensalt.net/uri/s2'")
                action.call
                expect(json_response['resources'].count).to eq(1)
                expect(json_response['resources'][0]['learningObjectives'].map { |x| x['targetName'] }).to match_array([s1.identifier, s2.identifier])
              end
            end

            context 'when filtering using learningObjectives.targetName' do
              context 'when given one targetName' do
                it 'returns resource' do
                  params.merge!(limit: 1, filter: "learningObjectives.targetName='#{s1.identifier}'")
                  action.call
                  expect(json_response['resources'].map { |el| el['name'] })
                    .to eq([resource.name])
                  expect(json_response['resources'][0]['learningObjectives'].map { |el| el['targetName'] })
                    .to match_array([s1.identifier, s2.identifier])
                end
              end

              context 'when given multiple filters' do
                context 'when given multiple targetNames' do
                  it 'returns resource using learningObjectives.targetName filter' do
                    params.merge!(limit: 1, filter: "learningObjectives.targetName='#{s1.identifier},#{s2.identifier}'")
                    action.call
                    expect(json_response['resources'].map { |el| el['name'] })
                      .to eq([resource.name])
                    expect(json_response['resources'][0]['learningObjectives'].map { |el| el['targetName'] })
                      .to match_array([s1.identifier, s2.identifier])
                  end
                end
              end
            end

            context 'when filtering using learningObjectives.caseItemGUID' do
              it 'returns resource' do
                params.merge!(limit: 1, filter: "learningObjectives.caseItemGUID~'s1'")
                action.call
                expect(json_response['resources'].count).to eq(1)
                expect(json_response['resources'][0]['learningObjectives'].map { |x| x['targetName'] }).to match_array([s1.identifier, s2.identifier])
              end
            end

            context 'when filtering using learningObjectives.targetDescription' do
              it 'returns resource' do
                params.merge!(limit: 1, filter: "learningObjectives.targetDescription='description'")
                action.call
                expect(json_response['resources'].count).to eq(1)
                expect(json_response['resources'][0]['learningObjectives'].map { |x| x['targetName'] }).to match_array([s1.identifier, s2.identifier])
              end

              context 'when filter matches no resources' do
                it 'doesnt return resource' do
                  params.merge!(limit: 1, filter: "learningObjectives.targetDescription='biology'")
                  action.call
                  expect(json_response['resources'].count).to eq(0)
                end
              end
            end

            context 'when filtering using extensions.expandObjectives' do
              let(:taxonomy) { FactoryBot.create(:taxonomy, identifier: 'SOME_MAPPED_TAXONOMY') }
              let(:taxonomy2) { FactoryBot.create(:taxonomy, identifier: 'TAX2') }
              let(:tax_map) do
                FactoryBot.create(:taxonomy_mapping, target_id: s1.id, taxonomy_id: taxonomy.id)
              end
              let(:tax_map2) do
                FactoryBot.create(:taxonomy_mapping, target_id: s2.id, taxonomy_id: taxonomy2.id)
              end
              let(:reversed_tax_map) do
                FactoryBot.create(:taxonomy_mapping, target_id: taxonomy.id, taxonomy_id: s1.id)
              end

              before do
                params.merge!(limit: 1, filter: "learningObjectives.targetName='#{taxonomy.identifier}'")
              end

              context 'when extensions.expandObjectives=true' do
                it 'searches by mapped taxonomies' do
                  params['extensions.expandObjectives'] = true
                  tax_map
                  action.call
                  expect(json_response['resources'].count).to eq(1)
                  expect(json_response['resources'][0]['learningObjectives'].map { |x| x['targetName'] }).to match_array([s1.identifier, s2.identifier])
                end

                it 'searches by mapped taxonomies using reverse mapping' do
                  params['extensions.expandObjectives'] = true
                  reversed_tax_map
                  action.call
                  expect(json_response['resources'].count).to eq(1)
                  expect(json_response['resources'][0]['learningObjectives'].map { |x| x['targetName'] }).to match_array([s1.identifier, s2.identifier])
                end

                it 'works if more than one standard is given' do
                  params.merge!(
                    'extensions.expandObjectives' => true,
                    filter: "learningObjectives.targetName='#{taxonomy.identifier},#{taxonomy2.identifier}'"
                  )

                  tax_map
                  tax_map2

                  action.call

                  objectives = json_response['resources'].first['learningObjectives']
                  objectives.map! { |el| el['targetName'] }

                  expect(objectives).to match_array([s1.identifier, s2.identifier])
                end
              end

              context 'when extensions.expandObjectives not set' do
                it "doesn't return mapped resources" do
                  tax_map
                  action.call
                  expect(json_response['resources'].count).to eq(0)
                end
              end

              context 'when extensions.expandObjectives = false' do
                it "doesn't return mapped resources" do
                  params['extensions.expandObjectives'] = false
                  tax_map
                  action.call
                  expect(json_response['resources'].count).to eq(0)
                end
              end
            end
          end

          context 'searches for not mapped params' do
            it 'returns some resources' do
              Search::FieldMap.instance.field_map.select { |x| x.is_a?(FieldTypes::NullField) }.map(&:input_field).each do |f|
                params.merge!(limit: 1, filter: "#{f}!='NULL'")
                action.call
                expect(json_response['resources'].count).to eq(1)
              end
            end
          end

          context 'searches by citext array' do
            let!(:r1) { FactoryBot.create :video, publisher: 'publisher', accessibility_input_methods: %w[fullMouseControl], access_mode: %w[auditory color textOnImage visual] }
            let!(:r2) { FactoryBot.create :other, publisher: 'publisher', accessibility_input_methods: %w[fullMouseControl] }
            let!(:r3) { FactoryBot.create :homework, publisher: 'publisher', accessibility_input_methods: %w[fullMouseControl fullKeyboardControl], access_mode: %w[textual itemSize] }

            context 'accessibilityInputMethods' do
              it "returns empty set for accessibilityInputMethods='NULL'(bc all resources can be controlled by mouse)" do
                params[:filter] = "accessibilityInputMethods='NULL'"
                action.call
                expect(json_response['resources'].count).to eq(0)
              end

              it "returns empty set for accessibilityInputMethods!='NULL'" do
                params[:filter] = "accessibilityInputMethods!='NULL'"
                action.call
                expect(json_response['resources'].count).to eq(4)
              end

              it "returns empty set for accessibilityInputMethods='fullKeyboardControl'" do
                params[:filter] = "accessibilityInputMethods='fullKeyboardControl'"
                action.call
                expect(json_response['resources'].count).to eq(1)
              end

              it "returns empty set for accessibilityInputMethods!='fullMouseControl'" do
                params[:filter] = "accessibilityInputMethods!='fullMouseControl'"
                action.call
                expect(json_response['resources'].count).to eq(0)
              end
            end

            context 'when filtering on accessMode' do
              context 'when searching for accessMode = null' do
                it 'returns resources with accessMode null/empty' do
                  params[:filter] = "accessMode='NULL'"
                  action.call
                  expect(json_response['resources'].count).to eq(1)
                  expect(json_response['resources'].first['accessMode'])
                    .to eq([''])
                end
              end

              context 'when searching for accessMode not null' do
                it 'returns resources with accessMode not null/empty' do
                  params[:filter] = "accessMode!='NULL'"
                  action.call
                  expect(json_response['resources'].count).to eq(3)
                  json_response['resources'].each do |res|
                    expect(res['accessMode'].first).to be_present
                  end
                end
              end

              context "when searching for accessMode='itemSize'" do
                it "returns resources where accessMode includes 'itemSize'" do
                  params[:filter] = "accessMode='itemSize'"
                  action.call
                  expect(json_response['resources'].count).to eq(1) # one Homework
                  expect(json_response['resources'].first['accessMode'])
                    .to include('itemSize')
                end
              end

              context "when searching for accessMode!='itemSize'" do
                it "returns resources where accessMode excludes 'itemSize'" do
                  params[:filter] = "accessMode!='itemSize'"
                  action.call
                  expect(json_response['resources'].count).to eq(2) # video + other
                  json_response['resources'].each do |res|
                    expect(res['accessMode']).to_not include('itemSize')
                  end
                end
              end
            end
          end

          context 'searches by ratings' do
            before(:each) do
              resource.rating = 3
              resource.save
            end

            it 'returns some resources where rating is not null' do
              params.merge!(limit: 1, filter: "rating!='NULL'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it 'returns some resources where rating <=3' do
              params.merge!(limit: 1, filter: "rating<='3'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it 'returns some resources where rating >3' do
              params.merge!(limit: 1, filter: "rating>'3'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end
          end

          context 'searches by publishDate' do
            it 'returns some resources by publishDate' do
              params.merge!(limit: 1, filter: "publishDate!='NULL'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            context 'resource within date inequality' do
              it 'returns resources appropriately' do
                params.merge!(limit: 1, filter: "publishDate>'2018-01-01'")
                action.call
                expect(json_response['resources'].count).to eq(1)
              end
            end

            context 'when resource out of range of date inequality' do
              it 'does not return the resource' do
                params.merge!(limit: 1, filter: "publishDate<='2018-01-01'")
                action.call
                expect(json_response['resources']).to be_blank
              end
            end
          end

          context 'searches by learningResourceType' do
            it 'doesnt return resources' do
              params.merge!(limit: 1, filter: "learningResourceType='Media/Video'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end

            it 'returns some resources' do
              params.merge!(limit: 1, filter: "learningResourceType='Game'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end
          end

          context 'searches by timeRequired' do
            before do
              resource.update!(time_required: ChronicDuration.parse('1m5s'))
            end

            it "doesn't return resources where timeRequired!=65sec" do
              params.merge!(limit: 1, filter: "timeRequired!='PT1M5S'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end

            it "doesn't return resources where timeRequired<65sec" do
              params.merge!(limit: 1, filter: "timeRequired<'PT1M5S'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end

            it 'returns resources where timeRequired>60sec' do
              params.merge!(limit: 1, filter: "timeRequired>'PT1M'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it 'returns resources where timeRequired=65sec' do
              params.merge!(limit: 1, filter: "timeRequired='PT1M5S'")
              action.call
              expect(json_response['resources'].count).to eq(1)
              expect(json_response['resources'][0]['timeRequired']).to eq('PT1M5S')
            end
          end

          context 'searches by publishDate' do
            it 'returns some resources' do
              params.merge!(limit: 1, filter: 'publishDate>"2010-02-18"')
              action.call
              expect(json_response['resources'].count).to eq(1)
            end
          end

          context 'searches by language' do
            it 'returns some resources' do
              params.merge!(limit: 1, filter: 'language="en"')
              action.call
              expect(json_response['resources'].count).to eq(1)
            end
          end

          context 'searches by typicalAgeRange' do
            it 'returns some resources' do
              params.merge!(limit: 1, filter: 'typicalAgeRange="6-7"')
              action.call
              expect(json_response['resources'].count).to eq(1)
              expect(json_response['resources'][0]['typicalAgeRange']).to eq('6-7')
            end
          end

          context 'searches by textComplexity' do
            before do
              resource.update!(text_complexity: { 'lexile' => 1.0, 'flesch-kincaid' => 2.0 })
            end

            it 'returns some resources with textComplexity' do
              params.merge!(limit: 1, fields: 'textComplexity', filter: "textComplexity!='NULL'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it 'returns some resources with textComplexity.name!="DRA"' do
              params.merge!(limit: 1, filter: "textComplexity.name!='DRA'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it 'doesnt return resources with textComplexity.name="DRA"' do
              params.merge!(limit: 1, filter: "textComplexity.name='DRA'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end

            it 'returns resources with textComplexity.value>=1' do
              params.merge!(limit: 1, filter: "textComplexity.value>='1'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it "returns resources with textComplexity.value!='NULL'" do
              params.merge!(limit: 1, filter: "textComplexity.value!='NULL'")
              action.call
              expect(json_response['resources'].count).to eq(1)
            end

            it "returns resources with textComplexity.value='NULL'" do
              params.merge!(limit: 1, filter: "textComplexity.value='NULL'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end

            it 'doesnt return resources with textComplexity.value<1' do
              params.merge!(limit: 1, filter: "textComplexity.value<'1'")
              action.call
              expect(json_response['resources'].count).to eq(0)
            end
          end
        end

        it 'returns resources without search parameters' do
          params[:limit] = 1
          action.call
          expect(response).to be_successful
          results = json_response
          action.call
          expect(results['resources']).to be_kind_of(Array)
          expect(results['resources'].length).to eq(1)
          expect(response.headers['X-Total-Count']).to eq(1)
        end

        context 'when searching for all fields' do
          let(:expected_result) do
            {
              'id' => resource.id,
              'name' => resource.name.to_s,
              'description' => resource.description.to_s,
              'subject' => [''],
              'url' => resource.url,
              'ltiLink' => {},
              'learningResourceType' => ['Game'],
              'language' => ['en'],
              'thumbnailUrl' => nil,
              'typicalAgeRange' => '6-7',
              'textComplexity' => [{ 'name' => 'Flesch-Kincaid', 'value' => '' }, { 'name' => 'Lexile', 'value' => '' }],
              'learningObjectives' => [],
              'author' => [],
              'publisher' => 'publisher',
              'useRightsUrl' => 'http://use_rights_url.com',
              'timeRequired' => '',
              'technicalFormat' => 'text/html',
              'educationalAudience' => ['student'],
              'accessibilityAPI' => [''],
              'accessibilityInputMethods' => ['fullMouseControl'],
              'accessibilityFeatures' => [''],
              'accessibilityHazards' => [''],
              'accessMode' => %w[orientation color textOnImage position visual],
              'publishDate' => resource.created_at.iso8601(3),
              'rating' => '0',
              'relevance' => 0,

              # Non-essential traits
              'extensions' => {},
              'efficacy' => [{ resource_stat.taxonomy.identifier => 77 }]
            }
          end

          it 'returns resources with all fields' do
            fields = Minerva::Search::FieldMap.instance.field_map.map { |_k, v| v.output_field }.uniq.compact.join(',')
            params.merge!(limit: 1, fields: fields)
            action.call

            expect(json_response['resources'][0].keys).to match_array(fields.split(',') << 'id')
            expect(json_response['resources'][0]).to eq(expected_result)
          end
        end

        context 'with regards to sorting' do
          include_examples 'sorting_examples'
        end

        context 'bad_request' do
          let(:error_description_wrong_filter) do
            valid_fields = Minerva::Search::FieldMap.instance.field_map.values.select(&:search_allowed).index_by(&:filter_field).compact
            "Use any of #{valid_fields.keys.join(', ')} fields in filter parameter"
          end

          specify 'for blank fields param' do
            params[:fields] = ''
            action.call
            expect(response).to be_a_bad_request
            expect(json_response['Description']).to eq('Please provide not empty fields parameter')
          end

          specify 'for wrong filter param' do
            params[:filter] = 'some wrong query'
            action.call
            expect(response).to be_a_bad_request
            expect(json_response['Description']).to eq('Wrong filter parameter')
          end

          context 'wrong filter' do
            let(:check) do
              lambda {
                action.call
                expect(response).not_to be_successful
                expect(json_response['Severity']).to eq('error')
                expect(json_response['Description']).to eq(error_description_wrong_filter)
              }
            end

            specify 'for wrong filter param(id)' do
              params[:filter] = "id='6'"
              check.call
            end

            specify 'for wrong filter param(url)' do
              params[:filter] = "url='example.com'"
              check.call
            end

            specify 'for not existing param(ioi)' do
              params[:filter] = "ioi='example.com'"
              check.call
            end
          end
        end

        context 'warnings' do
          let(:warning_description) do
            valid_fields =
              Minerva::Search::FieldMap.instance.field_map.values.select(&:output_field)
                                       .index_by(&:output_field).compact

            "Use any of #{valid_fields.keys.join(', ')} for fields parameter"
          end

          specify 'for wrong field name' do
            params[:fields] = 'oio,id'
            action.call
            expect(response).to be_successful

            expect(json_response['resources'].count).to eq(1)
            expect(json_response['resources'][0]['name']).to eq(resource.name)
            expect(json_response['Severity']).to eq('warning')
            expect(json_response['Description']).to eq(warning_description)
          end

          specify 'for wrong sorting field' do
            params[:sort] = 'oio'
            action.call
            expect(response).to be_successful
            expect(json_response['resources'].count).to eq(1)
            expect(json_response['Severity']).to eq('warning')
            expect(json_response['Description']).to eq('Use any of name, description, publisher, learningResourceType, language, typicalAgeRange, rating, publishDate, timeRequired, author for sorting parameter')
          end

          specify 'for wrong orderBy (should be asc/desc)' do
            params[:orderBy] = 'oio'
            action.call
            expect(response).to be_successful
            expect(json_response['resources'].count).to eq(1)
            expect(json_response['Severity']).to eq('warning')
            expect(json_response['Description']).to eq('Use asc or desc for orderBy parameter')
          end
        end
      end
    end
  end
end
