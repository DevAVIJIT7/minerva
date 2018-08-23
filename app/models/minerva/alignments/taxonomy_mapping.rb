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

# frozen_string_literal: true

module Minerva
  module Alignments
    class TaxonomyMapping < ApplicationRecord
      self.table_name = :taxonomy_mappings

      belongs_to :taxonomy, class_name: 'Minerva::Alignments::Taxonomy', foreign_key: 'taxonomy_id', inverse_of: :taxonomy_mappings
      belongs_to :target_taxonomy, class_name: 'Minerva::Alignments::Taxonomy', foreign_key: 'target_id',
                                   inverse_of: :target_taxonomy_mappings
    end
  end
end
