require 'sidekiq'
require 'sidekiq/job_retry'
require 'sidekiq/middleware/server/seize'

::Sidekiq.server_middleware do |chain|
  chain.insert_before(::Sidekiq::JobRetry, Sidekiq::Middleware::Server::Seize)
end
