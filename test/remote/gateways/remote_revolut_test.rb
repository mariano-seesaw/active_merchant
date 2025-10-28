require 'test_helper'

class RemoteRevolutTest < Test::Unit::TestCase
  def setup
    @gateway = RevolutGateway.new(fixtures(:revolut))
  end

  def test_successful_purchase
    amount = 10000
    options = {
      email: 'test@test.it'
    }
    response = @gateway.purchase(amount, nil, options)
    assert_success response
    assert_equal 'Order created successfully', response.message
  end

  def test_failed_purchase
    amount = -1000
    options = {
      email: 'test@test.it'
    }
    response = @gateway.purchase(amount, nil, options)
    assert_failure response
    assert_equal '400', response.error_code
    assert_equal 'Bad Request', response.message
  end
end
