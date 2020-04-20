# frozen_string_literal: true

module Minerva
  class Configuration
    attr_accessor :extension_fields, :authorizer, :search_by_taxonomy_aliases,
                  :filter_sql_proc, :count_resources_proc, :admin_auth_proc, :carrierwave, :after_search_proc,
                  :hidden_extensions_attrs, :order_first_sql_proc, :subjects_select_sql, :taxonomies_select_sql, :update_denormalized_data_sql

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
      @taxonomies_select_sql = "(select json_agg(json_build_object('id', taxonomies.id, 'opensalt_identifier', COALESCE(taxonomies.opensalt_identifier, ''),
                                'description', COALESCE(taxonomies.description, ''), 'alignment_type', COALESCE(taxonomies.alignment_type, ''), 'source',
                                COALESCE(taxonomies.source, ''), 'identifier', COALESCE(taxonomies.identifier, '')))
                                FROM taxonomies WHERE id = ANY(resources.direct_taxonomy_ids))"
      @update_denormalized_data_sql = "
      direct_taxonomy_ids = (SELECT coalesce(array_agg(taxonomies.id), '{}') FROM taxonomies
                             INNER JOIN alignments ON taxonomies.id = alignments.taxonomy_id
                             WHERE alignments.resource_id = resources.id AND alignments.status = #{Minerva::Alignments::Alignment::STATUS_CURATOR_CONFIRMED}),
      rejected_taxonomy_ids = (SELECT coalesce(array_agg(taxonomies.id), '{}') FROM taxonomies
                             INNER JOIN alignments ON taxonomies.id = alignments.taxonomy_id
                             WHERE alignments.resource_id = resources.id AND alignments.status = #{Minerva::Alignments::Alignment::STATUS_CURATOR_BAD}),
      all_taxonomy_ids = (SELECT coalesce(uniq(sort(array_remove(array_agg(taxonomies.id::int) || array_agg(taxonomy_mappings.taxonomy_id::int) || array_agg(taxonomy_mappings.target_id::int), NULL))), '{}')  FROM taxonomies
                             INNER JOIN alignments ON taxonomies.id = alignments.taxonomy_id
                             LEFT JOIN taxonomy_mappings ON taxonomies.id IN (taxonomy_mappings.taxonomy_id, taxonomy_mappings.target_id)
                             WHERE alignments.resource_id = resources.id AND alignments.status = #{Minerva::Alignments::Alignment::STATUS_CURATOR_CONFIRMED}),
      all_resource_stat_ids = (SELECT coalesce(array_agg(resource_stats.id), '{}') FROM resource_stats INNER JOIN alignments ON resource_stats.taxonomy_id = alignments.taxonomy_id WHERE alignments.resource_id = resources.id),
      all_subject_ids = (SELECT coalesce(array_agg(subjects.id), '{}') FROM subjects INNER JOIN resources_subjects ON resources_subjects.subject_id = subjects.id WHERE resources_subjects.resource_id = resources.id),
      avg_efficacy = (SELECT avg(resource_stats.effectiveness)  FROM resource_stats INNER JOIN alignments ON resource_stats.taxonomy_id = alignments.taxonomy_id WHERE alignments.resource_id = resources.id),
      efficacy = (SELECT replace(replace(replace(json_agg(CASE WHEN resource_stats.taxonomy_ident IS NOT NULL THEN json_build_object(taxonomies.identifier, resource_stats.effectiveness) ELSE '{}'::json END)::text, '}, {', ', '), ']', ''), '[', '')::jsonb
                 FROM resource_stats INNER JOIN alignments ON resource_stats.taxonomy_id = alignments.taxonomy_id INNER JOIN taxonomies ON taxonomies.id = alignments.taxonomy_id WHERE alignments.resource_id = resources.id)"

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
