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
    # Account updated
    when 'account.updated'
      handle_account_updated(stripe_event)
    # Creating customer event
    when 'customer.created'
      handle_customer_created(stripe_event)
    end
  end

  def handle_account_updated(stripe_event)
    # Extracting the stripe account object from data.json
    stripe_account = stripe_event.data.object
    account = Account.find_by(stripe_id: stripe_account.id)

    account.update(
      charges_enabled: stripe_account.charges_enabled,
      payouts_enabled: stripe_account.payouts_enabled,
    )
  end
  def handle_customer_created(stripe_event)
    # Stripe created customer event handler
    puts "Customer.created #{stripe_event.data.object_id}"
  end
end
