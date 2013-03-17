require 'capistrano/s3'

set :s3, YAML::load( File.open( File.expand_path( '../s3.yml', __FILE__ ) ) )
set :bucket, s3['bucket']
set :access_key_id, s3['access_key_id']
set :secret_access_key, s3['secret_access_key']
set :bucket_write_options, {
    cache_control: "max-age=94608000, public"
}

before 'deploy' do
  run_locally "bundle exec foreman run rake sinatra:export RACK_ENV=production"
  run_locally "bundle exec foreman run rake assetpack:build RACK_ENV=production"
end