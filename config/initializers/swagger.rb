SwaggerUiEngine.configure do |config|
  config.swagger_url = ENV.fetch("MINERVA_MOUNT_PATH", '/ims/rs/v1p0') + '/docs/swagger.yaml'
end
