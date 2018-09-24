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
  class ResourcesController < ApplicationController
    include ControllerPagination

    # GET /2/resources
    def index
      search_result = Search::Engine.new(params).perform
      set_pagination_headers(search_result.pagination)
      resources = ActiveModel::Serializer::CollectionSerializer.new(search_result.resources, serializer: ResourceSerializer,
                                                                    access_token: access_token, fields: params[:fields].try(:split, ','),
                                                                    warning: search_result.warning)
      render json: { resources: resources }.merge(search_result.warning)
    rescue Errors::LtiSearchError => ex
      render json: ex.error_data, status: :bad_request
    end

    # POST /2/resources
    def create
      resources = service.create(resource_params.merge(publish_date: DateTime.now))
      render json: resources, each_serializer: ResourceEditSerializer
    end

    # PATCH/PUT /2/resources/:id
    def update
      resource.update!(resource_params)
      render json: resource, serializer: ResourceEditSerializer
    end

    # DELETE /2/resources/:id
    def destroy
      resource.destroy
      head :ok
    end

    private

    def resource
      @resource ||= Resources::Resource.find(params.fetch(:id))
    end

    def resource_params
      params.permit(:csv_file_url, :csv_file, :name, :description, :url, :learning_resource_type, :language, :thumbnail_url,
                    :author, :publisher, :use_rights_url, :time_required, :technical_format,
                    :rating, :relevance, :state, lti_link: {}, text_complexity: {}, extensions: {}, subjects: [], taxonomies: [],
                                                 educational_audience: [], accessibility_api: [], accessibility_input_methods: [], accessibility_features: [], accessibility_hazards: [], access_mode: [])
    end

    def service
      @service ||= ResourceService.new
    end
  end
end
