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
  class Resource < ApplicationRecord
    self.table_name = :resources

    EDUCATIONAL_AUDIENCE = %w[student teacher administrator parent aide proctor guardian relative].freeze
    ACCESSIBILITY_API = %w[AndroidAccessibility ARIAv1 ATK AT-SPI BlackberryAccessibility iAccessible2 JavaAccessibility MacOSXAccessibility MSAA UIAutomation].freeze
    ACCESSIBILITY_INPUT_METHODS = %w[fullKeyboardControl fullMouseControl].freeze
    ACCESS_MODE = %w[auditory colour color itemSize olfactory orientation position tactile textOnImage textual visual].freeze
    ACCESSIBILITY_HAZARDS = %w[flashing motionSimulation olfactoryHazard sound].freeze
    TEXT_COMPLEXITY = %w[dra dale-chall flesch-kincaid fountas-pinnell lexile].freeze

    has_many :alignments, class_name: 'Minerva::Alignments::Alignment', dependent: :destroy
    has_many :taxonomies, class_name: 'Minerva::Alignments::Taxonomy', through: :alignments
    has_many :resources_subjects, class_name: 'Minerva::ResourcesSubject', dependent: :destroy
    has_many :subjects, class_name: 'Minerva::Subject', through: :resources_subjects
    has_many :resource_stats, class_name: 'Minerva::Alignments::ResourceStat', dependent: :destroy

    mount_uploader :cover, ::Minerva::CoverUploader

    validates :learning_resource_type, inclusion:
        { in: ['Assessment/Item', 'Assessment/Formative', 'Assessment/Interim', 'Assessment/Rubric', 'Assessment/Preparation', 'Collection/Course',
               'Collection/Unit', 'Collection/Lesson', 'Collection/Curriculum Guide', 'Game', 'Interactive/Simulation', 'Interactive/Animation',
               'Interactive/Whiteboard', 'Activity/Worksheet', 'Activity/Learning', 'Activity/Learning', 'Activity/Experiment', 'Lecture',
               'Text/Book', 'Text/Chapter', 'Text/Document', 'Text/Article', 'Text/Passage', 'Text/Textbook', 'Text/Reference',
               'Text/Website', 'Media/Audio', 'Media/Video', 'Media/Images', 'Other'] }, allow_nil: true

    validates :language, length: { is: 2 }, allow_nil: true
    validates :time_required, numericality: { greater_than: 0 }, allow_nil: true
    validate :validate_model

    after_update :update_denormalized_fields

    def self.update_denormalized_data(ids)
      Minerva::Resource.where(id: ids).update_all(Minerva.configuration.update_denormalized_data_sql)
    end

    def update_denormalized_fields
      self.class.update_denormalized_data([self.id])
    end

    private
    
    def validate_model
      if text_complexity && (!text_complexity.is_a?(Hash) || (text_complexity.keys.map(&:to_s) - TEXT_COMPLEXITY).present?)
        errors.add(:text_complexity, "should contain #{TEXT_COMPLEXITY} keys")
      end

      %i[educational_audience accessibility_api accessibility_input_methods accessibility_hazards access_mode].each do |v|
        val = send(v)
        if val.present? && (!val.is_a?(Array) || val.detect { |s| !(Resource.const_get(v.to_s.upcase).include? s) })
          errors.add(v, "should contain #{Resource.const_get(v.to_s.upcase)} elements")
        end
      end
    end
  end
end
