# SolidusSubscriptions

A Solidus extension for subscriptions.

## Installation

Add solidus_subscriptions to your Gemfile:

```ruby
gem 'solidus_subscriptions'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_subscriptions:install
```

# Configuration
This gem requires a gateway which supports credit cards in order to process
subscription orders. By default the gem will look for the first active gateway
with Spree::CreditCard as its `payment_source_class`.

If you would like to specify the gateway used by the gem you can add this to
an initialzer.

```ruby
SolidusSubscriptions::Config.default_gateway = my_gateway
```

# Usage

### Purchasing Subscriptions
By default only Spree::Variants are subscribable. To subscribe to a variant, it
must have the `:subscribable` attribute set to true.

To subscribe to a variant include the following parameters when posting to
`/orders/populate` (The add to cart button on the product page):

```js
  {
    // other add to cart params
    subscription_line_item: {
      quantity: 2,           // number of units in each subscription order,
      subscribable_id: 1234, // Which variant the subscription is for,
      interval: 2592000      // Time between subscription orders (in seconds... because Ruby),
      max_installments: 12   // Stop processing after this many subscription orders
                             // (use null to process the subscription ad nauseam)
    }
  }
```

This will associate a `SolidusSubscriptions::LineItem` to the line item
being added to the cart.

The customer will not be charged for the subscription until it is processed. The
subscription line items should be shown to the user on the cart page by
looping over `Spree::Order#subscription_line_items`.

When the order is finalized, a full `SolidusSubscriptions::Subscription` will be
created for each subscription line items associated to the order, through the
order's line items.

### Processing Subscriptions

To process actionable subscriptions simply run:

`bundle exec rake solidus_subscriptions:process`

To schedule this task we suggest using the [Whenever](https://github.com/javan/whenever) gem.

# Testing

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs, and [Rubocop](https://github.com/bbatsov/rubocop) static code analysis. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_subscriptions/factories'
```

Copyright (c) 2016 Stembolt, released under the New BSD License
