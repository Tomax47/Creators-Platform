class AddFinancialAccountIdToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :financial_account_id, :string
  end
end
