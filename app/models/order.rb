class Order < ActiveRecord::Base
  require 'active_merchant'
  has_many :transactions, :class_name => "OrderTransaction"

  attr_accessor :card_number, :card_verification
  validates :first_name, :last_name, :card_type, :card_number, :card_verification, :card_expires_on, presence: true

  def purchase
    response = credit_card
    transactions.create!(:action => "purchase", :amount => price_in_cents, :response => response) if response.success?
    response.success?
  end

  def price_in_cents
    (10*10).round
  end

  private

  def credit_card
    # Send requests to the gateway's test servers
    ActiveMerchant::Billing::Base.mode = :test

    #4111111111111111
    # Create a new credit card object
    @credit_card = ActiveMerchant::Billing::CreditCard.new(
      :type       => card_type,
      :number     => card_number,
      :month      => card_expires_on.month,
      :year       => card_expires_on.year,
      :first_name => first_name,
      :last_name  => last_name,
      :verification_value  => card_verification
    )


    if @credit_card.valid?

      # Create a gateway object to the TrustCommerce service
      gateway = ActiveMerchant::Billing::TrustCommerceGateway.new(
        :login    => 'TestMerchant',
        :password => 'password'
      )

      # Authorize for $10 dollars (1000 cents)
      response = gateway.authorize(price_in_cents, @credit_card)

      if response.success?
        gateway.capture(price_in_cents, response.authorization)
        return response
      end
    end
  end
end
