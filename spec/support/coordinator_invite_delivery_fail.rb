module CoordinatorInviteDeliveryFail
  class << self
    attr_accessor :raise_now

    def delivering_email(_mail)
      raise RuntimeError, "smtp down" if raise_now
    end
  end
end

RSpec.configure do |config|
  config.before { CoordinatorInviteDeliveryFail.raise_now = false }
end
