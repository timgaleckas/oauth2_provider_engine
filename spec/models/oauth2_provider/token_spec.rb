require 'spec_helper'

describe Oauth2Provider::Token do
  before  { @token = FactoryGirl.create(:oauth_token) }
  subject { @token }

  it { should validate_presence_of(:client_uri) }
  it { VALID_URIS.each{|uri| should allow_value(uri).for(:client_uri) } }
  it { should validate_presence_of(:resource_owner_uri) }
  it { VALID_URIS.each{|uri| should allow_value(uri).for(:resource_owner_uri) } }

  its(:token) { should_not be_nil }
  its(:refresh_token) { should_not be_nil }
  it { should_not be_blocked }

  context "#block!" do
    before { subject.block! }
    it { should be_blocked }
  end

  context ".block_client!" do
    before { @another_client_token = FactoryGirl.create(:oauth_token, client_uri: ANOTHER_CLIENT_URI) }
    before { Oauth2Provider::Token.block_client!(CLIENT_URI) }

    it { @token.reload.should be_blocked }
    it { @another_client_token.should_not be_blocked }
  end

  context ".block_access!" do
    before { @another_client_token = FactoryGirl.create(:oauth_token, client_uri: ANOTHER_CLIENT_URI)}
    before { @another_owner_token  = FactoryGirl.create(:oauth_token, resource_owner_uri: ANOTHER_USER_URI) }
    before { Oauth2Provider::Token.block_access!(CLIENT_URI, USER_URI) }

    it { @token.reload.should be_blocked }
    it { @another_client_token.should_not be_blocked }
    it { @another_owner_token.should_not be_blocked }
  end

  it "#expired?" do
    subject.should_not be_expired
    Delorean.time_travel_to("in #{Oauth2Provider.settings["token_expires_in"]} seconds")
    subject.should be_expired
  end

end
