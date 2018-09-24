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
  class ResourceEditSerializer < ActiveModel::Serializer
    attributes  :name, :description, :url, :learning_resource_type, :language, :thumbnail_url,
                :text_complexity, :author, :publisher, :use_rights_url, :time_required, :technical_format, :extensions,
                :rating, :relevance, :lti_link, :educational_audience, :accessibility_api, :accessibility_input_methods,
                :accessibility_features, :accessibility_hazards, :access_mode

    has_many :subjects, serializer: SubjectSerializer
    has_many :taxonomies, serializer: TaxonomySerializer
  end
end
