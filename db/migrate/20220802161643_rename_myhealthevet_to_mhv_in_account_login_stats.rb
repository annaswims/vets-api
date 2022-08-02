class RenameMyhealthevetToMHVInAccountLoginStats < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      rename_column :account_login_stats, :myhealthevet_at, :mhv_at
    end
  end
end
