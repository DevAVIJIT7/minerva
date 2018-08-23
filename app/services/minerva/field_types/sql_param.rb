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
  module FieldTypes
    class SqlParam
      def self.from(name_val_hash)
        name_val_hash.each_with_object({}) do |(k, v), result|
          uniq_sym = "#{k}_#{rand(10**10)}".to_sym
          result[k] = { uniq_sym: uniq_sym, value: v }
        end
      end

      def self.ar_params(sql_param_hash)
        sql_param_hash.values.map { |x| { x[:uniq_sym] => x[:value] } }.reduce({}, :merge)
      end
    end
  end
end
