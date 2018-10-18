# frozen_string_literal: true

require 'active_model_serializers'
require 'chronic_duration'
require 'faraday'
require 'extensions/object'
require 'hair_trigger'
require 'minerva/configuration'
require 'minerva/engine'
require 'rails_admin'

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
