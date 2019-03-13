module RailsAdmin
  module Config
    module Actions
      class Index < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :controller do
          proc do
            minerva_view = params[:model_name] == 'minerva~resource'
            if minerva_view && params[:minerva_query].present?
              query = Rack::Utils.parse_nested_query(params[:minerva_query]).symbolize_keys
              query.merge!({limit: RailsAdmin::Config.default_items_per_page,
                            offset: (params.fetch(:page, 1).to_i-1) * RailsAdmin::Config.default_items_per_page})
              result = Minerva::Search::Engine.new(query, nil).perform
              current_page = params.fetch(:page, 1).to_i
              total_pages = (result.pagination[:total_count] / (1.0*RailsAdmin::Config.default_items_per_page)).ceil
              @objects = Minerva::Resource.where(id: result.resources.map(&:id))
              @objects.define_singleton_method(:total_pages) { total_pages }
              @objects.define_singleton_method(:total_count) { result.pagination[:total_count] }
              @objects.define_singleton_method(:current_page) { current_page }
            else
              @objects = list_entries
            end

            unless @model_config.list.scopes.empty?
              if params[:scope].blank?
                unless @model_config.list.scopes.first.nil?
                  @objects = @objects.send(@model_config.list.scopes.first)
                end
              elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                @objects = @objects.send(params[:scope].to_sym)
              end
            end

            respond_to do |format|
              format.html do
                render minerva_view ? :minerva_index : @action.template_name, status: @status_code || :ok
              end

              format.json do
                output = begin
                  if params[:compact]
                    primary_key_method = @association ? @association.associated_primary_key : @model_config.abstract_model.primary_key
                    label_method = @model_config.object_label_method
                    @objects.collect { |o| {id: o.send(primary_key_method).to_s, label: o.send(label_method).to_s} }
                  else
                    @objects.to_json(@schema)
                  end
                end
                if params[:send_data]
                  send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.json"
                else
                  render json: output, root: false
                end
              end

              format.xml do
                output = @objects.to_xml(@schema)
                if params[:send_data]
                  send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.xml"
                else
                  render xml: output
                end
              end

              format.csv do
                header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options].permit!.to_h)
                if params[:send_data]
                  send_data output,
                            type: "text/csv; charset=#{encoding}; #{'header=present' if header}",
                            disposition: "attachment; filename=#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.csv"
                elsif Rails.version.to_s >= '5'
                  render plain: output
                else
                  render text: output
                end
              end
            end
          end
        end
      end

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
      [:created_at, :min_age, :max_age, :efficacy].each do |f|
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


