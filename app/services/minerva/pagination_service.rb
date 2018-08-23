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
  class PaginationService
    def initialize(collection, total_count)
      @collection = collection
      @total_count = total_count
    end

    def page(limit, offset)
      data        = @collection.limit(limit).offset(offset)
      pages       = set_page_numbers(limit, offset, @total_count)
      Search::SearchResult.new(resources: data.to_a, pagination: { total_count: @total_count, pages: pages, limit: limit })
    end

    def self.set_pagination_headers(pagination, request)
      links                    = create_links(pagination, request)
      headers['Link']          = links.join(', ') unless links.empty?
      headers['X-Total-Count'] = pagination[:total_count]
    end

    def self.create_links(pagination, request)
      url = request.url.split('?').first
      pages = pagination[:pages]
      limit = pagination[:limit]

      pages.inject([]) do |links, (key, value)|
        new_params = request.query_parameters.merge(offset: (value * limit) - limit, limit: limit)
        links << "<#{url}?#{new_params.to_param}>; rel=\"#{key}\""
      end
    end

    private

    def set_page_numbers(limit, offset, total_count)
      current_page = current_page(limit, offset)
      total_pages  = total_pages(limit, total_count)

      pages = {}
      pages[:first] = 1                if total_pages > 1 && current_page > 1
      pages[:prev]  = current_page - 1 if current_page > 1
      pages[:next]  = current_page + 1 if current_page < total_pages
      pages[:last]  = total_pages      if total_pages > 1 && current_page < total_pages
      pages
    end

    # Current page number
    def current_page(limit, offset)
      offset = 0 if offset < 0
      (offset / limit) + 1
    end

    # Total number of pages
    def total_pages(limit, count)
      count = 0 if count < 0
      (count.to_f / limit).ceil
    end
  end
end
