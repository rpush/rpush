class Queue
  class WakeupError < StandardError; end

  def wakeup(thread)
    @mutex.synchronize do
      t = @waiting.delete(thread)
      t.raise WakeupError if t
    end
  end
end