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

class Object
  def to_bool
    return true if self == true || self =~ /(true|t|yes|y|1)$/i
    return false if nil? || self == false || empty? || self =~ /(false|f|no|n|0)$/i
    raise ArgumentError, "invalid value for Boolean: \"#{self}\""
  end
end
