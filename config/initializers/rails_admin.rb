RailsAdmin.config do |config|

  config.authorize_with do |controller|
    Minerva.configuration.admin_auth_proc.call(controller)
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    bulk_delete
    show
    edit
    delete

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.model 'Minerva::Alignments::Taxonomy' do
    object_label_method do
      :identifier
    end

    [:taxonomy_mappings, :alignments, :target_taxonomy_mappings].each do |assoc|
      configure assoc do
        hide
        filterable false
        searchable false
      end
    end
  end

  config.model 'Minerva::Resource' do
    [:alignments, :resources_subjects].each do |assoc|
      configure assoc do
        hide
        filterable false
        searchable false
      end
    end
  end
end

require 'rails_admin/config/fields/base'
RailsAdmin::Config::Fields::Types::Json.inspect # Load before override.
class RailsAdmin::Config::Fields::Types::Json
  def queryable?
    false
  end
end

module RailsAdmin
  module Config
    module Fields
      module Types
        class Citext < RailsAdmin::Config::Fields::Types::String
          RailsAdmin::Config::Fields::Types::register(:citext, self)
        end
      end
    end
  end

  # Allow for searching/filtering of `citext` fields.
  module Adapters
    module ActiveRecord
      module CitextStatement
        private

        def build_statement_for_type
          if @type == :citext
            return build_statement_for_string_or_text
          else
            super
          end
        end
      end

      class StatementBuilder < RailsAdmin::AbstractModel::StatementBuilder
        prepend CitextStatement
      end
    end
  end
end


