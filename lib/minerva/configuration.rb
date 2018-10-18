# frozen_string_literal: true

module Minerva
  class Configuration
    attr_accessor :extension_fields, :authorizer, :search_by_taxonomy_aliases,
                  :filter_sql_proc, :admin_auth_proc

    def initialize
      @extension_fields = []
      @authorizer = nil
      @filter_sql_proc = nil
      @admin_auth_proc = Proc.new do |controller|
        controller.authenticate_or_request_with_http_basic('Minerva') do |username, password|
          controller.render(:json => "Forbidden", :status => 403, :layout => false)
        end
      end
      @search_by_taxonomy_aliases = true
    end
  end
end
