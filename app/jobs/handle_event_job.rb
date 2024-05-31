class HandleEventJob < ApplicationJob
  queue_as :default

  def perform(event)
    # Do something later
  end
end
