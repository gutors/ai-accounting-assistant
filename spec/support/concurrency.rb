module Concurrency
  def run_in_parallel(count = 2)
    threads = Array.new(count) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          yield
        end
      end
    end
    threads.each(&:join)
  end
end
