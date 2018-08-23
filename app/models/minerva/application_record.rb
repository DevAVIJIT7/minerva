# frozen_string_literal: true

module Minerva
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
