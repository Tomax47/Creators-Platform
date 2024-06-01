class StripeAccount
  include Rails.application.routes.url_helpers
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  def create_account
    return if account.stripe_id.present?

    stripe_account = Stripe::Account.create(
      type: 'custom',
      country: 'US',
      business_type: 'individual',
      email: account.user.email,
      individual: {
        email: account.user.email
      },
      business_profile: {
        product_description: 'Digital products',
        support_email: account.user.email,
      },
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
        # treasury: { requested: true },
        # card_issuing: { requested: true },
      },
    )
    account.update(stripe_id: stripe_account.id)
  end

  def onboarding_url
    Stripe::AccountLink.create({
        account: account.stripe_id,
        refresh_url: accounts_url,
        return_url: accounts_url,
        type: 'account_onboarding',
        collect: 'eventually_due',
      }).url
  end
end