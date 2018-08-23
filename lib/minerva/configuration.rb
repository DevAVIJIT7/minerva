# frozen_string_literal: true

module Minerva
  class Configuration
    attr_accessor :extension_fields, :authorizer, :model_extensions, :serializer_extensions

    def initialize
      @extension_fields = []
      @authorizer = nil
      @model_extensions = {}
      @serializer_extensions = {}
    end
  end
end
