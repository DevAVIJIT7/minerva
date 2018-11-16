module Minerva
  class CoverUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick

    storage Minerva.configuration.carrierwave_storage

    version :large do
      process resize_to_fill: [500,500]
    end

    version :medium do
      process resize_to_fill: [200,200]
    end

  end
end
