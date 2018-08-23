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

require 'ancestry'

module Minerva
  module Alignments
    class Taxonomy < ApplicationRecord
      self.table_name = :taxonomies

      has_ancestry orphan_strategy: :restrict

      has_many :alignments, class_name: 'Minerva::Alignments::Alignment', dependent: :destroy
      has_many :resources, class_name: 'Minerva::Resources::Resource', through: :alignments
      has_many :taxonomy_mappings, class_name: 'Minerva::Alignments::TaxonomyMapping', inverse_of: :taxonomy, dependent: :destroy
      has_many :target_taxonomy_mappings,
               class_name: 'Minerva::Alignments::TaxonomyMapping', inverse_of: :target_taxonomy,
               dependent: :destroy

      def ancestors_tree
        path.map(&:name)
      end
    end
  end
end
