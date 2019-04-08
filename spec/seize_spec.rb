require 'sidekiq'
require 'sidekiq/processor'

RSpec.describe Sidekiq::Middleware::Server::Seize do
  TEST_EXCEPTION = ArgumentError
  MAX_RETRY = 2

  def build_job_hash(worker_class, args=[])
    {'class' => worker_class, 'args' => args}
  end

  def fetch_retry_job
    retry_set = Sidekiq::RetrySet.new
    retry_job = retry_set.first
    retry_set.clear
    retry_job
  end

  def process_job(job_hash)
    mgr = instance_double('Manager', options: {:queues => ['default']})
    processor = ::Sidekiq::Processor.new(mgr)
    job_msg = Sidekiq.dump_json(job_hash)
    processor.process(Sidekiq::BasicFetch::UnitOfWork.new('queue:default', job_msg))
  end

  def initialize_middleware
    Sidekiq.server_middleware do |chain|
      chain.add Sidekiq::Middleware::Server::Seize
    end
  end

  def initialize_worker_class(sidekiq_opts=nil)
    worker_class_name = :TestDummyWorker
    Object.send(:remove_const, worker_class_name) if Object.const_defined?(worker_class_name)
    klass = Class.new do
      include Sidekiq::Worker
      sidekiq_options sidekiq_opts if sidekiq_opts
      def perform
        raise TEST_EXCEPTION, 'Oops'
      end
    end
    Object.const_set(worker_class_name, klass)
  end

  def cleanup_redis
    Sidekiq.redis {|c| c.flushdb }
  end

  shared_examples_for 'it should raise multiple errors' do
    it 'throws exception on each retry' do
      args ||= []
      expect {
        process_job(build_job_hash(worker_class, args))
      }.to raise_error(TEST_EXCEPTION, 'Oops')
      expect(Sidekiq::RetrySet.new.size).to eq(1)
      retry_job = fetch_retry_job
      expect(retry_job['retry_count']).to eq(0)
      expect(retry_job['error_class']).to eq('ArgumentError')
      expect(retry_job['error_message']).to eq('Oops')

      expect {
        process_job(retry_job.item)
      }.to raise_error(TEST_EXCEPTION, 'Oops')
      expect(Sidekiq::RetrySet.new.size).to eq(1)
      retry_job = fetch_retry_job
      expect(retry_job['retry_count']).to eq(1)
      expect(retry_job['error_class']).to eq('ArgumentError')
      expect(retry_job['error_message']).to eq('Oops')

      expect {
        process_job(retry_job.item)
      }.to raise_error(TEST_EXCEPTION, 'Oops')
      expect(Sidekiq::RetrySet.new.size).to eq(0)
    end
  end

  shared_examples_for 'it should raise 1 errors' do
    it 'raises the original error at the end' do
      args ||= []
      expect {
        process_job(build_job_hash(worker_class, args))
      }.to_not raise_error(TEST_EXCEPTION)
      expect(Sidekiq::RetrySet.new.size).to eq(1)
      retry_job = fetch_retry_job
      expect(retry_job['retry_count']).to eq(0)

      expect {
        process_job(retry_job.item)
      }.to_not raise_error(TEST_EXCEPTION)
      expect(Sidekiq::RetrySet.new.size).to eq(1)
      retry_job = fetch_retry_job
      expect(retry_job['retry_count']).to eq(1)

      expect {
        process_job(retry_job.item)
      }.to raise_error(TEST_EXCEPTION, 'Oops')
      expect(Sidekiq::RetrySet.new.size).to eq(0)
    end
  end

  shared_examples_for 'retry disabled, it should raise one error' do
    it 'raises the error' do
      args ||= []
      expect {
        process_job(build_job_hash(worker_class, args))
      }.to raise_error(TEST_EXCEPTION, 'Oops')
      expect(Sidekiq::RetrySet.new.size).to eq(0)
    end
  end

  before(:each) do
    cleanup_redis
  end

  context 'with default middleware config' do
    before(:each) do
      initialize_middleware
    end

    describe 'with nothing explicitly enabled' do
      it_behaves_like 'retry disabled, it should raise one error' do
        let!(:worker_class) { initialize_worker_class(retry: false) }
      end

      it_behaves_like 'retry disabled, it should raise one error' do
        let!(:worker_class) { initialize_worker_class(retry: 0) }
      end

      it_behaves_like 'it should raise multiple errors' do
        let!(:worker_class) { initialize_worker_class(retry: MAX_RETRY) }
      end
    end

    describe 'with seize explicitly disabled' do
      it_behaves_like 'retry disabled, it should raise one error' do
        let!(:worker_class) { initialize_worker_class(seize: false, retry: 0) }
      end

      it_behaves_like 'retry disabled, it should raise one error' do
        let!(:worker_class) { initialize_worker_class(seize: false, retry: false) }
      end

      it_behaves_like 'it should raise multiple errors' do
        let!(:worker_class) { initialize_worker_class(seize: false, retry: MAX_RETRY) }
      end
    end

    describe 'with seize explicitly enabled' do
      it_behaves_like 'it should raise 1 errors' do
        let!(:worker_class) { initialize_worker_class(seize: true, retry: MAX_RETRY) }
      end

      it_behaves_like 'retry disabled, it should raise one error' do
        let!(:worker_class) { initialize_worker_class(seize: true, retry: false) }
      end

      it_behaves_like 'retry disabled, it should raise one error' do
        let!(:worker_class) { initialize_worker_class(seize: true, retry: 0) }
      end
    end
  end
end
