module Minerva
  class CoverUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick

    storage Minerva.configuration.carrierwave[:storage]

    Minerva.configuration.carrierwave[:versions].each do |v|
      version v[:name] do
        process resize_to_fill: v[:size_w_h]
      end
    end

    def store_dir
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

  end
end
