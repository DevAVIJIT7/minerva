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
  class ResourceType
    VIDEO = 'Media/Video'
    Audio = 'Media/Audio'
    LESSON_PLAN = 'Collection/Lesson'
    INTERACTIVE = 'Interactive/Simulation'
    GAME = 'Game'
    QUESTION = 'Assessment/Item'
    ASSESSMENT = 'Assessment/Formative'
    HOMEWORK = 'Assessment/Preparation'
    OTHER = 'Other'
  end
end