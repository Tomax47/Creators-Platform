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
  def ensure_financial_account
    return if !account.financial_account_id.nil?

    # Stripe financial account docs https://docs.stripe.com/treasury/account-management/financial-accounts
    financial_account = Stripe::Treasury::FinancialAccount.create(
      {
        supported_currencies: ['usd'],
        features: {
          card_issuing: { requested: true },
          deposit_insurance: { requested: true },
          # Requesting access to the account routing number "Like the bank account routing number"
          financial_addresses: { aba: { requested: true } },
          inbound_transfers: { ach: { requested: true } },
          intra_stripe_flows: { requested: true },
          outbound_payments: {
            ach: { requested: true },
            us_domestic_wire: { requested: true },
          },
          outbound_transfers: {
            ach: { requested: true },
            us_domestic_wire: { requested: true },
          },
        },
      },
        # Passing the stripe account header for the user account to create the financial account
        header)
  end

  def retrieve_financial_account
    return if account.financial_account_id.nil?
    @financial_account ||= Stripe::Treasury::FinancialAccount.retrieve(
      {
        id: account.financial_account_id,
        # Expanding to get the account number to be sued later on for issuing "Default financial account retrieval does not get this number back without specifying through expand"
        expand: ['financial_addresses.aba.account_number'],
      }, header)
  end
  def ensure_external_account
    return if !account.external_account_id.nil?
    # Fetching the financial account
    account_info = financial_account.financial_addresses.first.aba

    # Using the aba addresses on the financial account to create ana external account
    bank_account = Stripe::Account.create_external_account(
      account.stripe_id,
      {
        external_account: {
        object: 'bank_account',
        account_number: account_info.account_number,
        routing_number: account_info.routing_number,
        country: 'US',
        currency: 'usd'
        },
        default_for_currency: true,
      })

    # Updating account's external id
    account.update(external_account_id: bank_account.id)
  end

  def financial_balances
    return if retrieve_financial_account.nil?

    retrieve_financial_account.balance
  end

  def payments_balances
    @payment_balances ||= Stripe::Balance.retrieve(header)
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

  # Helper
  def header
    { stripe_account: account.stripe_id }
  end
end
