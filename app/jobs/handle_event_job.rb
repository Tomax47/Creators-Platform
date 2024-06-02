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

    # When the treasury is activated on the user account
    when 'capability.updated'
      handle_capability_updated(stripe_event)

    # Handle financial account status updated
    when 'treasury.financial_account.features_status_updated'
    handle_financial_account_features_status_updated(stripe_event)
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

  def handle_capability_updated(stripe_event)
    capability = stripe_event.data.object
    if capability.id == 'treasury' && capability.status == 'active'
      # Create financila account for the connected user
      account = Account.find_by(stripe_id: capability.account)
      service = StripeAccount.new(account)
      service.ensure_financial_account
    end
  end

  def handle_financial_account_features_status_updated(stripe_event)
    financial_account = stripe_event.data.object
    if financial_account.active_features.include?('financial_addresses.aba')
      # Creating an external account with the account and the routing number of the user's account
      account = Account.find_by(stripe_id: stripe_event.account)
      service = StripeAccount.new(account)
      service.ensure_external_account
    end
  end
end
