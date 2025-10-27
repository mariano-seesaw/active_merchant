module ActiveMerchant # :nodoc:
  module Billing # :nodoc:
    class FlywireGateway < Gateway
      self.test_url = 'https://api-platform-sandbox.flywire.com/'
      self.live_url = 'https://api-platform.flywire.com/'

      self.supported_countries = ['US']
      self.default_currency = 'USD'
      self.supported_cardtypes = %i[visa master american_express discover]

      self.homepage_url = 'https://www.flywire.com/'
      self.display_name = 'Flywire Gateway'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options = {})
        requires!(options, :api_key)
        super
      end

      def purchase(money, _payment, options = {})
        post = {
          type: 'tokenization_and_pay',
          charge_intent: {
            mode: 'unscheduled'
          },
          options: {
            form: {
              action_button: 'save',
              locale: options[:locale] || 'en',
              show_flywire_logo: true
            }
          },
          schema: 'cards',
          recipient_id: options[:recipient_id],
          payor_id: options[:payor_id]
        }
        add_additional_fields(post, options)
        add_invoice(post, money, options)

        commit('purchase', endopoint('purchase'), post)
      end

      def authorize(_money, _payment, options = {})
        commit('authorize', endopoint('authorize', options), nil)
      end

      def supports_scrubbing?
        false
      end

      private

      def add_additional_fields(post, options)
        if options[:additional_fields]
          post[:recipient] ||= {}
          post[:recipient][:fields] ||= []
          post[:recipient][:fields].concat(options[:additional_fields])
        end
      end

      def add_invoice(post, money, options)
        post[:items] = [
          {
            id: 'default',
            amount: money
          }
        ]
      end

      def header
        {
          'X-Authentication-Key' => @options[:api_key],
          'Content-Type' => 'application/json'
        }
      end

      def endopoint(action, parameters = {})
        url = (test? ? test_url : live_url)
        case action
        when 'purchase'
          "#{url}payments/v1/checkout/sessions"
        when 'authorize'
          "#{url}payments/v1/checkout/sessions/#{parameters[:session_id]}/confirm"
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
          'Checkout session created successfully'
        when 'authorize'
          'Payment created successfully'
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
