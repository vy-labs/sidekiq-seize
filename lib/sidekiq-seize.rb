require 'sidekiq'
require 'sidekiq/middleware/server/seize'

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::Seize
  end
end
