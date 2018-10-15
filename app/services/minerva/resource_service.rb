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

require 'csv'
module Minerva
  class ResourceService
    def create(params)
      if params[:csv_file]
        load_from_csv(File.read(params[:csv_file].path))
      elsif params[:csv_file_url]
        load_from_csv(Faraday.get(params[:csv_file_url]).body)
      else
        if params[:subjects].present?
          params[:subject_ids] = params[:all_subject_ids] = Subject.where(name: params.delete(:subjects)).pluck(:id)
        end
        if params[:taxonomies].present?
          params[:taxonomy_ids] = params[:direct_taxonomy_ids] = Alignments::Taxonomy.where('lower(identifier) in (:terms) OR lower(opensalt_identifier) in (:terms)',
                                                                 terms: params.delete(:taxonomies)).pluck(:id)
        end
        [Resource.create!(params)]
      end
    end

    private

    def load_from_csv(csv_string)
      data = CSV.parse(csv_string)
      cols = Resource.columns.index_by(&:name)
      relation_cols = %w[taxonomies subjects]
      headers = data[0]
      resources = data[1..-1].map do |row|
        res_params = headers.each_with_index.each_with_object({}) do |(col, idx), result|
          raise ArgumentError, 'wrong column in csv file' if !headers.include?(col) && !relation_cols.include?(col)
          value = row[idx]
          if value.present?
            if col == 'subjects'
              col = 'subject_ids'
              value = Subject.where(name: JSON.parse(value)).pluck(:id)
            elsif col == 'taxonomies'
              col = 'taxonomy_ids'
              terms = JSON.parse(value).map(&:downcase)
              value = Alignments::Taxonomy.where('lower(identifier) in (:terms) OR lower(opensalt_identifier) in (:terms)', terms: terms)
                                          .pluck(:id)
            end
          end
          if %i[json jsonb].include?(cols[col]&.type) || cols[col]&.array
            value = begin
                      JSON.parse(value)
                    rescue StandardError
                      nil
                    end
          end
          result[col] = value
        end
        Resource.create!(res_params)
      end
      Resource.update_denormalized_data(resources.map(&:id))
      resources
    end
  end
end
