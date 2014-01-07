module AcceptanceTestsSignInHelper
  include Warden::Test::Helpers
  Warden.test_mode!

  def sign_in!
    user = FactoryGirl.create :user, @visitor
    login_as(user)
    user
  end
end

RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.include AcceptanceTestsSignInHelper, type: :feature
end
