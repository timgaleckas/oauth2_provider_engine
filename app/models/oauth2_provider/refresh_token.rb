module Oauth2Provider
  class RefreshToken
    include Mongoid::Document
    include Mongoid::Timestamps

    field :refresh_token
    field :access_token

    validates :access_token, presence: true

    before_create :random_refresh_token

    private

    def random_refresh_token
      self.refresh_token = SecureRandom.hex(Oauth2Provider.settings["random_length"])
    end

  end
end
