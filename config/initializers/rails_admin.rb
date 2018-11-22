module RailsAdmin
  module Config
    module Actions
      class Import < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :collection do
          true	#	this is for all records in all models
        end

        register_instance_option :link_icon do
          "icon-folder-open"
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do
            @import_model = @abstract_model

            if request.post?
              Minerva::Resource.transaction do
                @resources = Minerva::ResourceService.new.create({csv_file: params[:file]})
              end
              if @resources.blank?
                flash[:error] = "Import went wrong"
              else
                flash[:success] = "Successful import"
              end
            end
            render action: @action.template_name
          end
        end
      end

      class ImportFromYoutube < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :collection do
          true
        end

        register_instance_option :link_icon do
          "icon-play"
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do
            if request.post?
              Minerva::YoutubeJob.perform_later(params[:youtube_channel])
              flash[:success] = "The job was started"
            end
            render action: @action.template_name
          end
        end
      end
    end
  end
end

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
    import do
      only Minerva::Resource
    end
    if ENV['YOUTUBE_API_KEY']
      import_from_youtube do
        only Minerva::Resource
      end
    end
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

    list do
      field :name
      field :created_at do
        date_format :short
      end
      field :url
      field :publisher
      field :learning_resource_type
    end
    edit do
      include_all_fields
      field :cover, :carrierwave
      [:created_at, :avg_efficacy, :min_age, :max_age, :efficacy].each do |f|
        field f do
          read_only true
        end
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


