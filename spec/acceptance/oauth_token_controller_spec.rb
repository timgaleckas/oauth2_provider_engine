require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "TokenController" do
  before { Oauth2Provider::Client.destroy_all }
  before { Oauth2Provider::Access.destroy_all }
  before { Oauth2Provider::RefreshToken.destroy_all }

  let(:user)          { FactoryGirl.create(:user) }
  let(:client)        { FactoryGirl.create(:client) }
  let(:client_read)   { FactoryGirl.create(:client_read) }
  let(:authorization) { FactoryGirl.create(:oauth_authorization) }
  let(:access)        { FactoryGirl.create(:oauth_access) }
  let(:write_scope)   { "pizzas" }
  let(:read_scope)    { "pizzas/read" }

  before { @scope = FactoryGirl.create(:scope_pizzas_read) }
  before { @scope = FactoryGirl.create(:scope_pizzas_all) }
  before { Oauth2Provider::TokenController.any_instance.stub(:user_url).and_return( USER_URI ) }

  context "Authorization token flow" do

    let(:attributes) { {
      grant_type: "authorization_code",
      client_id: client.uri,
      client_secret: client.secret,
      code: authorization.code,
      redirect_uri: client.redirect_uri
    } }

    scenario "create a token" do
      create_token_uri(attributes)
      response_should_have_access_token
      response_should_have_refresh_token
    end

    context "when client is blocked" do
      it "should not load authorization page" do
        client.block!
        create_token_uri(attributes)
        page.should have_content "Client blocked"
      end
    end

    context "when access is blocked (resource owner block a client)" do
      it "should not load authorization page" do
        access.block!
        create_token_uri(attributes)
        page.should have_content "Client blocked from the user"
      end
    end

    context "when not valid" do
      scenario "fails with not valid code" do
        attributes.merge!(code: "not_existing")
        create_token_uri(attributes)
        page.should have_content "Authorization not found"
      end

      scenario "fails with no valid client uri" do
        attributes.merge!(client_id: "not_existing")
        create_token_uri(attributes)
        page.should have_content "Client not found"
      end

      scenario "fails when authorization is expired" do
        authorization.expire_at # hack (otherwise do not set the time)
        Delorean.time_travel_to("in #{Oauth2Provider.settings["authorization_expires_in"]} seconds")
        create_token_uri(attributes)
        page.should have_content "Authorization expired"
        page.should have_content "less than 5 seconds"
      end

    end
  end


  context "Password credentials flow" do
    let(:attributes) { {
      grant_type: "password",
      client_id: client.uri,
      client_secret: client.secret,
      username: user.email,
      password: user.password,
      scope: write_scope
    } }

    scenario "create a token" do
      create_token_uri(attributes)
      response_should_have_access_token
      response_should_have_refresh_token
    end

    context "when client is blocked" do
      it "should not load authorization page" do
        client.block!
        create_token_uri(attributes)
        page.should have_content "Client blocked"
      end
    end

    context "when access is blocked (resource owner block a client)" do
      it "should not load authorization page" do
        access.block!
        create_token_uri(attributes)
        page.should have_content "Client blocked from the user"
      end
    end

    context "when not valid" do
      scenario "fails with not valid user password" do
        attributes.merge!(password: "not_existing")
        create_token_uri(attributes)
        page.should have_content "User not found"
      end

      scenario "fails with no valid client uri" do
        attributes.merge!(client_id: "not_existing")
        create_token_uri(attributes)
        page.should have_content "Client not found"
      end

      scenario "fails with no valid scope authorization" do
        attributes.merge!({client_id: client_read.uri, client_secret: client_read.secret })
        create_token_uri(attributes)
        page.should have_content "Client not authorized"
      end
    end
  end


  context "Refresh Token" do
    let(:token)         { FactoryGirl.create(:oauth_token) }
    let(:refresh_token) { Oauth2Provider::RefreshToken.create(access_token: token.token) }

    let(:attributes) { {
      grant_type: "refresh_token",
      refresh_token: refresh_token.refresh_token,
      client_id: client.uri,
      client_secret: client.secret
    } }

    scenario "create an access token" do
      create_token_uri(attributes)
      response_should_have_access_token
      response_should_have_refresh_token
    end

    context "when client is blocked" do
      scenario "should not load authorization page" do
        client.block!
        create_token_uri(attributes)
        page.should have_content "Client blocked"
      end
    end

    context "when access is blocked (resource owner block a client)" do
      scenario "should not load authorization page" do
        access.block!
        create_token_uri(attributes)
        page.should have_content "Client blocked from the user"
      end
    end

    context "when token is blocked (resource owner log out)" do
      scenario "should not load authorization page" do
        token.block!
        create_token_uri(attributes)
        page.should have_content "Access token blocked from the user"
      end
    end

    context "when not valid" do
      scenario "fails with no valid client uri" do
        attributes.merge!(client_id: "not_existing")
        create_token_uri(attributes)
        page.should have_content "Client not found"
      end

      scenario "fails with no valid refresh token" do
        attributes.merge!(refresh_token: "not_existing")
        create_token_uri(attributes)
        page.should have_content "Refresh token not found"
      end
    end
  end

  context "Authorization token flow" do
    before { @token = FactoryGirl.create(:oauth_token) }

    scenario "block a token" do
      page.driver.delete("/oauth/token/" + @token.token)
      #@token.reload.should be_blocked
      #page.status_code.should == 200
    end
  end
end
