require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "Oauth2Provider::AccessesController" do
  before { host! "http://" + host }
  before { @user   = FactoryGirl.create(:user) }
  before { @client = FactoryGirl.create(:client) }
  before { @token  = FactoryGirl.create(:oauth_token) }
  before { @access = FactoryGirl.create(:oauth_access) }
  before { Oauth2Provider::AccessesController.any_instance.stub(:user_url).with(@user).and_return( USER_URI ) }

  context ".index" do
    before { @uri = "/oauth/accesses" }

    context "when not logged in" do
      scenario "is not authorized" do
        visit @uri
        current_url.should == host + "/log_in"
      end
    end

    context "when logged in" do
      before { login(@user) }

      scenario "view all resources" do
        visit @uri
        page.should have_content @access.client_uri
        page.should have_content "Block!"
      end

      scenario "block a resource" do
        visit @uri
        page.should have_link "Block!"
        page.click_link "Block!"
        page.should have_link "Unblock!"
      end
    end
  end


  context ".show" do
    before { @uri = "/oauth/accesses/" + @access.id.as_json }

    context "when not logged in" do
      scenario "is not authorized" do
        visit @uri
        current_url.should == host + "/log_in"
      end
    end

    context "when logged in" do
      before { login(@user) }
      before { @access_not_owned = FactoryGirl.create(:oauth_access, resource_owner_uri: ANOTHER_USER_URI) }

      scenario "view a resource" do
        visit @uri
        page.should have_content @access.client_uri
      end

      scenario "resource not found" do
        @access.destroy
        visit @uri
        page.should have_content "Resource not found"
      end

      scenario "resource not owned" do
        visit "/oauth/accesses/" + @access_not_owned.id.as_json
        page.should have_content "Resource not found"
      end

      scenario "illegal id" do
        visit "/oauth/accesses/0"
        page.should have_content "Resource not found"
      end
    end
  end

end
