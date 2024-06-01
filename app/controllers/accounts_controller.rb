class AccountsController < ApplicationController
  before_action :authenticate_user!
  def index
  end

  def create
    @account = Account.find_or_create_by(user: current_user)

    service = StripeAccount.new(@account)
    service.create_account
    # URL hosted by another host "Stripe" -> We have to allow other hosts, set the status to see_other so it redirects
    redirect_to service.onboarding_url, allow_other_host: true, status: :see_other
  end
end
