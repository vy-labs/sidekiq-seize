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
        rescue Exception => e
          options = worker.sidekiq_options_hash || {}
          bubble_exception(options, job, e)
          attempt_retry(worker, job, queue, e)
        end

        private

        def bubble_exception(options, job, e)
          raise e unless in_seize_mode?(options)
          raise e unless retry_allowed?(options)
          raise e unless seize_class?(options, e)

          retry_count = job['retry_count'] || 0
          last_try = retry_count ==  max_attempts_for(options) - 1
          raise e if last_try
        end

        def retry_allowed?(options)
          return false if !options['retry'].nil? && options['retry'] == false
          return false if !options['retry'].nil? && options['retry'] == 0
          true
        end

        def in_seize_mode?(options)
          !options['seize'].nil? && options['seize'] == true
        end

        def seize_class?(options, e)
          return true if options['seize_exceptions_classes'].nil?

          options['seize_exceptions_classes'].each do |klass|
            return true if klass == e.class
          end

          false
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
