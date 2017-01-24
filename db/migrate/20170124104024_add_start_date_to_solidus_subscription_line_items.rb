class AddStartDateToSolidusSubscriptionLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :solidus_subscriptions_line_items, :start_date, :date
  end
end
