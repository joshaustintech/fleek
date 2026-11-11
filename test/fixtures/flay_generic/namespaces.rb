module Billing
  module Gateways
    class Stripe < Base
      ENDPOINT = ::Billing::Config::STRIPE_URL

      def charge(amount, currency: "usd", **options, &callback)
        response = client&.post(ENDPOINT, { amount: amount, currency: currency, **options })
        callback.call(response) if callback
        response[:status] = :charged
        response
      end
    end

    class Braintree < Base
      ENDPOINT = ::Billing::Config::BRAINTREE_URL

      def charge(total, currency: "eur", **extra, &handler)
        result = client&.post(ENDPOINT, { amount: total, currency: currency, **extra })
        handler.call(result) if handler
        result[:status] = :charged
        result
      end
    end
  end
end
