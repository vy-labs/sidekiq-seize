require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq/api'
require 'byebug'

module Sidekiq
  module Middleware
    module Server
      class Seize
        include Sidekiq::Util

        def call(worker, job, _queue)
          yield
        rescue StandardError => e
          options = worker.sidekiq_options_hash || {}
          bubble_exception(options, job, e)
        end

        private

        def bubble_exception(options, job, e)
          raise e if options['seize'].nil? || options['seize'] == false
          raise e if !options['retry'].nil? && options['retry'] == false
          raise e if !options['retry'].nil? && options['retry'] == 0
          max_retries = job['retries'] || ::Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS
          retry_count = job['retry_count'] || 0
          last_try = !job['retry'] || retry_count == max_retries - 1

          raise e if last_try
        end
      end
    end
  end
end
