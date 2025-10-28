require 'test_helper'

class FlywireTest < Test::Unit::TestCase
  def setup
    @gateway = FlywireGateway.new(api_key: 'API_KEY')
  end

  def test_successful_purchase
    amount = 1000000
    options = {
      booking_reference: 'booking123',
      recipient_id: 'DLD',
      payor_id: 'user123'
    }
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    response = @gateway.purchase(amount, nil, options)
    assert_success response

    assert_equal 'Checkout session created successfully', response.message
    assert response.test?
  end

  def test_failed_purchase
    amount = 1000000
    options = {
      booking_reference: 'booking123',
      recipient_id: 'DLD',
      payor_id: 'user123'
    }
    @gateway.expects(:ssl_post).raises(::ActiveMerchant::ResponseError.new(stub('422 Response', code: '422', message: 'Unprocessable Entity')))

    response = @gateway.purchase(amount, nil, options)
    assert_failure response
    assert_equal '422', response.error_code
    assert_equal 'Unprocessable Entity', response.message
  end

  def test_successful_authorize
    options = {
      session_id: 'f4da5b90-591a-4255-a86b-18a621c8724b'
    }
    @gateway.expects(:ssl_post).returns(successful_authorize_response)

    response = @gateway.authorize(nil, nil, options)
    assert_success response

    assert_equal 'Payment created successfully', response.message
    assert response.test?
  end

  def test_failed_authorize
    options = {
      session_id: '123456789'
    }
    @gateway.expects(:ssl_post).raises(::ActiveMerchant::ResponseError.new(stub('422 Response', code: '422', message: 'Unprocessable Entity')))

    response = @gateway.authorize(nil, nil, options)
    assert_failure response
    assert_equal '422', response.error_code
    assert_equal 'Unprocessable Entity', response.message
  end

  private

  def successful_purchase_response
    '{
      "id":"34b6e07d-f201-453d-8ba6-ae04812dc210",
      "expires_at":"2025-10-21T16:25:15.117+00:00",
      "expires_in_seconds":1800,
      "hosted_form":{
        "url":"https://payment-checkout.demo.flywire.com/v1/form?session_id=34b6e07d-f201-453d-8ba6-ae04812dc210",
        "method":"GET"
      },
      "warnings":[]
    }'
  end

  def successful_authorize_response
    '{
      "payment_reference": "DLD675215743",
      "charge_info":
      {
        "amount": 330000,
        "currency": "EUR"
      },
      "payment_method":
      {
        "token": "e63150faed607bef51b0",
        "type": "card",
        "brand": "visa",
        "card_classification": "credit",
        "card_expiration": "03/2030",
        "last_four_digits": "1111",
        "country": "US",
        "issuer": "FLYWIRE BANK SVCs"
      },
      "mandate":
      {
        "id": "MCDLD20251027EpI7CIiM",
        "currency": "EUR"
      },
      "payor":
      {
        "country": "IT",
        "email": "test@test.it"
      }
    }'
  end
end
