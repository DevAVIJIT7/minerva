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
  class ResourceSerializer < ActiveModel::Serializer

    attribute :id

    def self.reload_attributes
      Minerva::Search::FieldMap.instance.field_map.each do |_k, v|
        next if v.output_field.blank?
        attribute v.output_field, if: -> { include_attr?(v) }
      end
    end
    reload_attributes

    def include_attr?(field)
      if instance_options[:warning][:CodeMinor] != :invalid_selection_field && instance_options[:fields].present?
        instance_options[:fields].include?(field.output_field.to_s)
      else
        true
      end
    end

    def subject
      attr_or_default(object.subject)
    end

    def learningResourceType
      # TODO: Possibly change column "learning_resource_type" to array of multiple
      # resource types and allow searching through the array
      [object.learning_resource_type].compact
    end

    def url
      object.url
    end

    def thumbnailUrl
      object.thumbnail_url
    end

    def ltiLink
      object.lti_link
    end

    def learningObjectives
      (object.learning_objectives || []).map do |s|
        { caseItemGUID: s['opensalt_identifier'],
          caseItemUri: (s['source'] || '').start_with?('http') ? s['source'] : '',
          alignmentType: s['alignment_type'],
          targetName: s['identifier'],
          targetDescription: s['description'] }
      end
    end

    def typicalAgeRange
      object.typical_age_range
    end

    def useRightsUrl
      object.use_rights_url
    end

    def timeRequired
      return nil unless object.time_required.present?

      "PT#{ChronicDuration.output(object.time_required.to_i, format: :short).delete(' ').upcase}"
    end

    def technicalFormat
      object.technical_format || 'text/html'
    end

    def educationalAudience
      attr_or_default(object.educational_audience, ['student'])
    end

    def accessibilityAPI
      attr_or_default(object.accessibility_api)
    end

    def textComplexity
      result = object.text_complexity
      result.each { |el| el['value'] = el['value'].to_s }
      result
    end

    def accessibilityInputMethods
      attr_or_default(object.accessibility_input_methods)
    end

    def accessibilityFeatures
      attr_or_default(object.accessibility_features)
    end

    def accessibilityHazards
      attr_or_default(object.accessibility_hazards)
    end

    def extensions
      object.extensions || {}
    end

    def language
      [object.language].compact
    end

    def relevance
      object.relevance || 0
    end

    def publishDate
      object.publish_date
    end

    def author
      [object.author].compact
    end

    def accessMode
      attr_or_default(object.access_mode)
    end

    def rating
      (object.rating || '0').to_s
    end

    private

    def attr_or_default(attribute, default = [])
      attribute.present? ? attribute : default
    end
  end
end
