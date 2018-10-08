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

module Minerva
  module Alignments
    class Alignment < ApplicationRecord
      self.table_name = :alignments

      belongs_to :resource, class_name: 'Minerva::Resource'
      belongs_to :taxonomy, class_name: 'Minerva::Alignments::Taxonomy'

      STATUS_CURATOR_CONFIRMED = 2
      STATUS_CURATOR_BAD = 3

      before_validation do
        self.status ||= STATUS_CURATOR_CONFIRMED
      end
    end
  end
end
