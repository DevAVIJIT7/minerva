# frozen_string_literal: true

require 'active_model_serializers'
require 'chronic_duration'
require 'faraday'
require 'extensions/object'
require 'hair_trigger'
require 'minerva/configuration'
require 'minerva/engine'
require 'google/apis/youtube_v3'
require 'rails_admin'
require 'swagger_ui_engine'
require 'carrierwave'
require 'carrierwave-aws'

module Minerva
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
