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

require 'singleton'
module Minerva
  module Search
    class FieldMap
      include Singleton

      attr_accessor :minerva_map

      TEXT_COMPLEXITY_SELECT = "jsonb_build_array(json_build_object('name', 'Flesch-Kincaid', 'value', resources.text_complexity->>'flesch-kincaid'), json_build_object('name', 'Lexile', 'value', resources.text_complexity->>'lexile'))"
      AGE_RANGE_SELECT = "(SELECT CASE WHEN resources.min_age IS NULL THEN resources.max_age::text
                                      WHEN resources.max_age IS NULL THEN resources.min_age::text
                                      WHEN resources.max_age IS NOT NULL AND resources.max_age = resources.min_age THEN resources.min_age::text
                                      ELSE concat_ws('-', resources.min_age, resources.max_age)
                                      END)"

      ALL_CLASSES = [Minerva::Resource, Minerva::Alignments::ResourceStat, Minerva::Subject, Minerva::Alignments::Taxonomy].freeze

      RELEVANCE_COLUMNS = %w(tsv_text tsv_name tsv_description tsv_subjects)

      def generate_field_map
        minerva_map.select { |x| x.custom_search || @available_columns.include?(x.query_field) }.index_by(&:filter_field)
      end

      def field_map
        @field_map ||= generate_field_map
      end

      def extension_fields
        @extension_fields ||= field_map.select { |_k, v| v.is_extension }.map { |k, v| v }
      end

      def add_query_field(query_field)
        raise 'query_field should have to_sql method' unless query_field.respond_to?(:to_sql)
        minerva_map << query_field
        @field_map = generate_field_map
      end

      private

      def initialize
        # Minerva can have extensions, which can extend search engine, but minerva itself shouldn't know about it,
        # that's why it checks available columns and removes query fields from field_map, which db doesn't support
        @available_columns = begin
          ALL_CLASSES.map { |cls| cls.column_names.map { |c_name| "#{cls.table_name}.#{c_name}" } }.flatten
        rescue ActiveRecord::StatementInvalid, PG::UndefinedTable, ActiveRecord::NoDatabaseError
          []
        end

        @minerva_map = [
          FieldTypes::SearchField.new('search', nil, nil, query_field: 'tsv_text', custom_search: true, is_sortable: true, tsv_column: 'tsv_text'),
          FieldTypes::CaseInsensitiveString.new('name', 'resources.name', :name, is_sortable: true, tsv_column: 'tsv_name'),
          FieldTypes::CaseInsensitiveString.new('description', 'resources.description', :description, is_sortable: true, tsv_column: 'tsv_description'),
          FieldTypes::CaseInsensitiveString.new('publisher', 'resources.publisher', :publisher, is_sortable: true),
          FieldTypes::Subject.new('subject', Minerva.configuration.subjects_select_sql, :subject, query_field: 'all_subject_ids', custom_search: true, tsv_column: 'tsv_subjects'),
          FieldTypes::Efficacy.new('efficacy', 'resources.efficacy', :efficacy,  query_field: 'resources.efficacy', is_sortable: true, field_type: 'int', is_extension: true),
          FieldTypes::Numeric.new('avg_efficacy', 'resources.avg_efficacy', :avg_efficacy,  query_field: 'resources.avg_efficacy', is_sortable: true),
          FieldTypes::LearningObjective.new('learningObjectives', Minerva.configuration.taxonomies_select_sql, :learningObjectives, query_field: 'taxonomies.identifier', as_option: :learning_objectives),
          FieldTypes::LearningObjective.new('learningObjectives.id', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.id'),
          FieldTypes::LearningObjective.new('learningObjectives.targetName', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.identifier'),
          FieldTypes::LearningObjective.new('learningObjectives.caseItemGUID', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.opensalt_identifier'),
          FieldTypes::LearningObjective.new('learningObjectives.alignmentType', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.alignment_type'),
          FieldTypes::LearningObjective.new('learningObjectives.targetDescription', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.description'),
          FieldTypes::LearningObjective.new('learningObjectives.targetURL', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, custom_search: true),
          FieldTypes::LearningObjective.new('learningObjectives.educationalFramework', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, custom_search: true),
          FieldTypes::LearningObjective.new('learningObjectives.caseItemUri', Minerva.configuration.taxonomies_select_sql, :learningObjectives, as_option: :learning_objectives, query_field: 'taxonomies.source'),
          FieldTypes::LearningResourceTypeField.new('learningResourceType', 'resources.learning_resource_type', :learningResourceType, as_option: :learning_resource_type, is_sortable: true),
          FieldTypes::CaseInsensitiveString.new('language', 'resources.language', :language, is_sortable: true),
          FieldTypes::TypicalAgeRange.new('typicalAgeRange', AGE_RANGE_SELECT, :typicalAgeRange, as_option: :typical_age_range, custom_search: true),
          FieldTypes::CaseInsensitiveString.new('rating', 'resources.rating', :rating, is_sortable: true),
          FieldTypes::Timestamp.new('publishDate', 'resources.publish_date', :publishDate, as_option: :publish_date, is_sortable: true),
          FieldTypes::Duration.new('timeRequired', 'resources.time_required', :timeRequired, as_option: :time_required, is_sortable: true),
          FieldTypes::CaseInsensitiveString.new('author', 'resources.author', :author, is_sortable: true),
          FieldTypes::CaseInsensitiveString.new('useRightsUrl', 'resources.use_rights_url', :useRightsUrl, as_option: :use_rights_url),
          FieldTypes::TextComplexity.new('textComplexity', TEXT_COMPLEXITY_SELECT, :textComplexity, as_option: :text_complexity, query_field: 'resources.text_complexity'),
          FieldTypes::TextComplexity.new('textComplexity.name', TEXT_COMPLEXITY_SELECT, :textComplexity, as_option: :text_complexity, query_field: 'resources.text_complexity'),
          FieldTypes::TextComplexity.new('textComplexity.value', TEXT_COMPLEXITY_SELECT, :textComplexity, as_option: :text_complexity, query_field: 'resources.text_complexity'),
          FieldTypes::CaseInsensitiveString.new('thumbnailUrl', 'resources.thumbnail_url', :thumbnailUrl, as_option: :thumbnail_url),
          FieldTypes::CaseInsensitiveString.new('technicalFormat', 'resources.technical_format', :technicalFormat, as_option: :technical_format),
          FieldTypes::StringArray.new('accessibilityAPI', 'resources.accessibility_api', :accessibilityAPI, as_option: :accessibility_api),
          FieldTypes::StringArray.new('accessibilityInputMethods', 'resources.accessibility_input_methods', :accessibilityInputMethods, as_option: :accessibility_input_methods),
          FieldTypes::StringArray.new('accessMode', 'resources.access_mode', :accessMode, as_option: :access_mode),
          FieldTypes::StringArray.new('educationalAudience', 'resources.educational_audience', :educationalAudience, as_option: :educational_audience),
          FieldTypes::StringArray.new('accessibilityFeatures', 'resources.accessibility_features', :accessibilityFeatures, as_option: :accessibility_features),
          FieldTypes::StringArray.new('accessibilityHazards', 'resources.accessibility_hazards', :accessibilityHazards, as_option: :accessibility_hazards),
          FieldTypes::CaseInsensitiveString.new('extensions', 'resources.extensions', :extensions),
          FieldTypes::CaseInsensitiveString.new('relevance', 'resources.relevance', :relevance),
          FieldTypes::NullField.new('ltiLink', 'resources.lti_link', :ltiLink, as_option: :lti_link, search_allowed: false, custom_search: true),
          FieldTypes::NullField.new('relevance', '1', :relevance, query_field: 'relevance', as_option: :relevance, search_allowed: false, custom_search: true, is_sortable: true, is_extension: true),
          FieldTypes::CaseInsensitiveString.new('url', 'resources.url', :url, search_allowed: false)
        ] + (Minerva.configuration.extension_fields || [])
      end
    end
  end
end
