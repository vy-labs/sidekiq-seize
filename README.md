# seize

Sidekiq middleware that allows capturing exceptions and throwing only after last retry, useful for integrations with sentry and airbrake when you don't want to raise exceptions on each retry.

#### Installation

gem 'sidekiq-seize'

Worker example:
``` ruby
  class MyWorker
    include Sidekiq::Worker
    sidekiq_options seize: true

    def perform(params)
      ...
    end
  end
```

#### Implementation Details

This middleware inherits from sidekiq `JobRetry` middleware, all exceptions in each retry until the final retry are captured and job is manually put into retry. For the last retry exception is raised naturally. 
