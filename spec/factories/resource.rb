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

FactoryBot.define do
  sequence :url do |n|
    "http://example.com/page#{n}.html"
  end

  sequence :name do |n|
    "Resource #{n}"
  end

  sequence :description do |n|
    "Resource description #{n}"
  end

  sequence :publisher do |n|
    "Publisher #{n}"
  end

  factory :resource, class: Minerva::Resource do
    name
    description
    publisher
    url
    learning_resource_type { 'Media/Video' }
  end

  factory :video, class: Minerva::Resource, parent: :resource do
    learning_resource_type { 'Media/Video' }
  end

  factory :game, class: Minerva::Resource, parent: :resource do
    learning_resource_type { 'Game' }
  end

  factory :homework, class: Minerva::Resource, parent: :resource do
    learning_resource_type { 'Assessment/Preparation' }
  end

  factory :other, class: Minerva::Resource, parent: :resource do
    learning_resource_type { 'Other' }
  end
end
