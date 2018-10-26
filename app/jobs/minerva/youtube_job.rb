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
  class YoutubeJob < ActiveJob::Base

    def perform(channel_id)
      resp = yt_service.list_channels('content_details', { id: channel_id })
      resp.items.each do |channel|
        uploads_list_id = channel.content_details.related_playlists.uploads
        load_playlist_videos(uploads_list_id)
      end
    end

    private

    def yt_service
      @yt_service = Google::Apis::YoutubeV3::YouTubeService.new
      @yt_service.key ||= ENV['YOUTUBE_API_KEY']
      @yt_service
    end

    def load_playlist_videos(uploads_list_id)
      if uploads_list_id
        response = nil

        while response.nil? || response.next_page_token
          params = {
              playlist_id: uploads_list_id,
              page_token: response.try(:next_page_token),
              max_results: 50
          }

          response = yt_service.list_playlist_items('snippet', params)
          video_ids = response.items.map { |x| x.snippet.resource_id.video_id }
          contentDetails = yt_service.list_videos("contentDetails", id: video_ids.join(',')).items.index_by(&:id)
          exist_video_ids = Resource.where(youtube_id: video_ids).pluck(:youtube_id)
          response.items.each do |playlist_item|
            attrs = get_video_details(playlist_item, contentDetails)
            Resource.create!(attrs) unless exist_video_ids.include?(attrs[:youtube_id])
          end
        end
      end
    end

    def get_video_details(item, contentDetails)
      attrs = {}
      video_id = item.snippet.resource_id.video_id
      attrs[:url] = "https://www.youtube.com/watch?v=#{video_id}"
      attrs[:thumbnail_url] = "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg"
      attrs[:embeddable] = true
      attrs[:learning_resource_type] = ResourceType::VIDEO
      attrs[:name] = item.snippet.title.strip
      attrs[:youtube_id] = video_id
      attrs[:publisher] = item.snippet.channel_title
      attrs[:description] = item.snippet.description.presence
      attrs[:publish_date] = DateTime.now
      attrs[:time_required] = ChronicDuration.parse(contentDetails[video_id].content_details.duration)
      attrs
    end

  end
end