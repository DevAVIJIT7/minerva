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
  describe Resource do
    specify 'update_denormalized_data' do
      r = FactoryBot.create(:resource)
      t1 = FactoryBot.create(:taxonomy)
      t2 = FactoryBot.create(:taxonomy)
      t3 = FactoryBot.create(:taxonomy)
      r.taxonomies = [t1, t2]
      taxon_mapping = FactoryBot.create(:taxonomy_mapping, taxonomy: t1, target_taxonomy: t3)
      stat =  FactoryBot.create(:resource_stat, resource: r, taxonomy: t1, taxonomy_ident: t1.identifier, effectiveness: 20)
      stat2 =  FactoryBot.create(:resource_stat, resource: r, taxonomy: t2, taxonomy_ident: t2.identifier, effectiveness: 30)
      subject = FactoryBot.create(:subject)
      r.subjects = [subject]
      Resource.update_denormalized_data([r.id])
      expect(r.reload.direct_taxonomy_ids).to match_array([t1.id, t2.id])
      expect(r.all_taxonomy_ids).to match_array([t1.id, t2.id, t3.id])
      expect(r.resource_stat_ids).to match_array([stat.id, stat2.id])
      expect(r.all_subject_ids).to match_array([subject.id])
      expect(r.avg_efficacy).to eq(25)
      expect(r.efficacy).to eq({t1.identifier => 20, t2.identifier => 30})
    end
  end
end