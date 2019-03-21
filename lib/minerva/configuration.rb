# frozen_string_literal: true

module Minerva
  class Configuration
    attr_accessor :extension_fields, :authorizer, :search_by_taxonomy_aliases,
                  :filter_sql_proc, :admin_auth_proc, :carrierwave, :after_search_proc,
                  :hidden_extensions_attrs

    def initialize
      @extension_fields = []
      @hidden_extensions_attrs = []
      @authorizer = nil
      @carrierwave = { storage: :aws, versions: [{ name: :large, size_w_h: [500,500] },
                                                 { name: :medium, size_w_h: [200,200] }] }
      @filter_sql_proc = nil
      @admin_auth_proc = Proc.new do |controller|
        controller.authenticate_or_request_with_http_basic('Minerva') do |username, password|
          controller.render(:json => "Forbidden", :status => 403, :layout => false)
        end
      end
      @after_search_proc = nil
      @search_by_taxonomy_aliases = true
    end
  end
end
