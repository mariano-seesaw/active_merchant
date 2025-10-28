require 'test_helper'

class RevolutTest < Test::Unit::TestCase
  def setup
    @gateway = RevolutGateway.new(api_key: 'API_KEY')
  end

  def test_successful_purchase
    amount = 10000
    options = {
      email: 'test@test.it'
    }
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    response = @gateway.purchase(amount, nil, options)
    assert_success response

    assert_equal 'Order created successfully', response.message
    assert response.test?
  end

  def test_failed_purchase
    amount = 10000
    options = {
      email: 'test@test.it'
    }
    @gateway.expects(:ssl_post).raises(::ActiveMerchant::ResponseError.new(stub('400 Response', code: '400', message: 'Bad Request')))

    response = @gateway.purchase(amount, nil, options)
    assert_failure response
    assert_equal '400', response.error_code
    assert_equal 'Bad Request', response.message
  end

  private

  def successful_purchase_response
    '{
      "id": "690098da-c01f-ae29-8e1e-51e94a9c4ea5",
      "token": "a3df04b6-8732-4d0f-b1dc-bdfe8ef4d8d0",
      "type": "payment",
      "state": "pending",
      "created_at": "2025-10-28T10:20:10.589535Z",
      "updated_at": "2025-10-28T10:20:10.589535Z",
      "amount": 10000,
      "currency": "EUR",
      "outstanding_amount": 10000,
      "capture_mode": "automatic",
      "checkout_url": "https://sandbox-checkout.revolut.com/payment-link/a3df04b6-8732-4d0f-b1dc-bdfe8ef4d8d0",
      "enforce_challenge": "automatic",
      "customer": {
        "id": "aa8e5558-fb31-48c6-b128-9870e876c3df",
        "email": "test@test.it"
      }
    }'
  end
end
