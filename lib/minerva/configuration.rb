# frozen_string_literal: true

module Minerva
  class Configuration
    attr_accessor :extension_fields, :authorizer, :search_by_taxonomy_aliases,
                  :filter_sql_proc, :count_resources_proc, :admin_auth_proc, :carrierwave, :after_search_proc,
                  :hidden_extensions_attrs, :order_first_sql_proc, :subjects_select_sql

    def initialize
      @extension_fields = []
      @hidden_extensions_attrs = []
      @authorizer = nil
      @carrierwave = { storage: :aws, versions: [{ name: :large, size_w_h: [500,500] },
                                                 { name: :medium, size_w_h: [200,200] }] }
      @filter_sql_proc = nil
      @count_resources_proc = nil
      @order_first_sql_proc = nil
      @subjects_select_sql = '(select array_agg(subjects.name) from subjects WHERE id = ANY(resources.all_subject_ids))'
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
