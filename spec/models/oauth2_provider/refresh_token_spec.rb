require 'spec_helper'

describe Oauth2Provider::RefreshToken do
  before  { @token = FactoryGirl.create(:oauth_token) }
  before  { @refresh_token = Oauth2Provider::RefreshToken.create(access_token: @token.token) }
  subject { @refresh_token }

  it { should validate_presence_of :access_token }

  its(:refresh_token) {should_not be_nil }
end
