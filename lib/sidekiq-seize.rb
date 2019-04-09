require 'sidekiq'
require 'sidekiq/middleware/server/seize'

::Sidekiq.server_middleware do |chain|
  chain.add Sidekiq::Middleware::Server::Seize
end
