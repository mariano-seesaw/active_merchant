module ActiveMerchant # :nodoc:
  module Billing # :nodoc:
    class RevolutGateway < Gateway
      self.test_url = 'https://sandbox-merchant.revolut.com/'
      self.live_url = 'https://merchant.revolut.com/'

      self.supported_countries = ['US']
      self.default_currency = 'EUR'
      self.supported_cardtypes = %i[visa master american_express discover]

      self.homepage_url = 'https://www.revolut.com/'
      self.display_name = 'Revolut Gateway'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options = {})
        requires!(options, :api_key)
        super
      end

      def purchase(money, _payment, options = {})
        post = {
          currency: options.present? && options[:currency].present? ? options[:currency] : self.default_currency,
          amount: money,
          customer: {
            email: options[:email]
          }
        }
        add_additional_fields(post, options)

        commit('purchase', endopoint('purchase'), post)
      end

      def supports_scrubbing?
        false
      end

      private

      def add_additional_fields(post, options)
        post[:customer] ||= {}
        post[:customer][:email] = options[:email]
      end

      def header
        {
          'Revolut-Api-Version' => '2024-09-01',
          'Authorization' => "Bearer #{@options[:api_key]}",
          'Content-Type' => 'application/json'
        }
      end

      def endopoint(action)
        url = (test? ? test_url : live_url)
        case action
        when 'purchase'
          "#{url}api/orders"
        end
      end

      def commit(action, endopoint, parameters)
        begin
          response = parse(ssl_post(endopoint, parameters&.to_json, header), action)
        rescue ActiveMerchant::ResponseError => e
          response = parse_error(e.response)
        end

        Response.new(
          response[:success],
          response[:message],
          response[:body] || {},
          {
            test: test?,
            error_code: response[:error_code]
          }
        )
      end

      def message_from(action)
        case action
        when 'purchase'
          'Order created successfully'
        end
      end

      def parse(body, action)
        response = {}
        response[:message] = message_from(action)
        response[:success] = true
        response[:body] = JSON.parse(body)
        response
      end

      def parse_error(http_response)
        response = {}
        response[:error_code] = http_response.code
        response[:message] = http_response.message
        response[:success] = false
        response
      end
    end
  end
end
