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
  class ResourcesSubject < ApplicationRecord
    self.table_name = :resources_subjects

    belongs_to :resource, inverse_of: :resources_subjects, class_name: 'Minerva::Resources::Resource'
    belongs_to :subject, inverse_of: :resources_subjects, class_name: 'Minerva::Subject'
  end
end
