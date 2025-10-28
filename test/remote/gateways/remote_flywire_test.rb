require 'test_helper'

class RemoteFlywireTest < Test::Unit::TestCase
  def setup
    @gateway = FlywireGateway.new(fixtures(:flywire))
  end

  def test_successful_purchase
    amount = 1000000
    options = {
      recipient_id: 'DLD',
      payor_id: 'user123',
      additional_fields: [
        { id: 'booking_reference', value: 'booking123' },
        { id: 'agree_to_terms_and_conditions', value: 'true' }
      ]
    }
    response = @gateway.purchase(amount, nil, options)
    assert_success response
    assert_equal 'Checkout session created successfully', response.message
  end

  def test_failed_purchase
    options = {
      recipient_id: 'DLD',
      payor_id: 'user123',
      additional_fields: [
        { id: 'booking_reference', value: 'booking123' },
        { id: 'agree_to_terms_and_conditions', value: 'true' }
      ]
    }
    amount = -1000
    response = @gateway.purchase(amount, nil, options)
    assert_failure response
    assert_equal '422', response.error_code
    assert_equal 'Unprocessable Entity', response.message
  end

  # NOTE: Chiamare l'authorize più volte sullo stesso session_id ritorna errore 422
  # def test_successful_authorize
  #   options = {
  #     session_id: 'f4da5b90-591a-4255-a86b-18a621c8724b'
  #   }
  #   response = @gateway.authorize(nil, nil, options)
  #   assert_success response
  #   assert_equal 'Payment created successfully', response.message
  # end

  def test_failed_authorize
    options = {
      session_id: '123456789'
    }
    response = @gateway.authorize(nil, nil, options)
    assert_failure response
    assert_equal '422', response.error_code
    assert_equal 'Unprocessable Entity', response.message
  end
end
