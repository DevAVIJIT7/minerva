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

Minerva.configure do |config|
  config.authorizer = proc do |controller|
  end

  config.extension_fields = []
  config.search_by_taxonomy_aliases = true

  config.admin_auth_proc = Proc.new do |controller|
    authenticate_or_request_with_http_basic('Minerva') do |username, password|
      controller.render(:json => "Forbidden", :status => 403, :layout => false)
    end
  end

end
