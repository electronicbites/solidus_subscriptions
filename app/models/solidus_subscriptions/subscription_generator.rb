# This module is responsible for taking SolidusSubscriptions::LineItem
# objects and creating SolidusSubscriptions::Subscription Objects
module SolidusSubscriptions
  module SubscriptionGenerator
    # Create and persist a collection of subscriptions
    #
    # @param subscription_line_items [Array<SolidusSubscriptions::LineItem>] The
    #   subscription_line_items to be activated
    #
    # @return [Array<SolidusSubscriptions::Subscription>]
    def self.activate(subscription_line_items)
      subscription_line_items.map do |subscription_line_item|
        order = subscription_line_item.order

        subscription_attributes = {
          user: order.user,
          line_item: subscription_line_item,
          shipping_address: order.ship_address
        }

        Subscription.create!(subscription_attributes) do |sub|
          sub.actionable_date = sub.next_actionable_date
        end
      end
    end
  end
end
