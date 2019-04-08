require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq/api'
require 'sidekiq/job_retry'

module Sidekiq
  module Middleware
    module Server
      class Seize < ::Sidekiq::JobRetry

        def call(worker, job, queue)
          yield
        rescue StandardError => e
          options = worker.sidekiq_options_hash || {}
          bubble_exception(options, job, e)
          attempt_retry(worker, job, queue, e)
        end

        private

        def bubble_exception(options, job, e)
          raise e if options['seize'].nil? || options['seize'] == false
          raise e unless retry_allowed?(options)

          retry_count = job['retry_count'] || 0
          last_try = retry_count ==  max_attempts_for(options) - 1
          raise e if last_try
        end

        def retry_allowed?(options)
          return false if !options['retry'].nil? && options['retry'] == false
          return false if !options['retry'].nil? && options['retry'] == 0
          true
        end

        def max_attempts_for(options)
          if options['retry'].is_a?(Integer)
            options['retry']
          else
            @max_retries
          end
        end
      end
    end
  end
end
