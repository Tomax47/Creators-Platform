class HandleEventJob < ApplicationJob
  queue_as :default

  def perform(event)
    # Job handler based on the event source
    case event.source
    when 'stripe'
      handle_stripe_event(event)
    end
  end

  def handle_stripe_event(event)
    # Constructing an instance of the stripe event object from the data of the event
    stripe_event = Stripe::Event.construct_from(event.data)

    case stripe_event.type
    # Creating customer event
    when 'customer.created'
      handle_customer_created(stripe_event)
    end
  end
  def handle_customer_created(stripe_event)
    # Stripe created customer event handler
    puts "Customer.created #{stripe_event.data.object_id}"
  end
end
