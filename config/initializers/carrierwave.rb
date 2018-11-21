CarrierWave.configure do |config|
  config.storage    = :aws
  config.aws_acl    = 'public-read'
  config.asset_host = ENV.fetch('ASSETS_HOST', nil)

  config.aws_attributes = {
      expires: 1.week.from_now.httpdate,
      cache_control: 'max-age=604800'
  }
  unless Rails.env.test?
    config.aws_bucket = ENV.fetch('S3_BUCKET')
    config.aws_credentials = {
        access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
        region:            ENV.fetch('AWS_REGION'),
    }
  end
  config.aws_credentials = (config.aws_credentials || {}).merge(stub_responses: Rails.env.test?)
end