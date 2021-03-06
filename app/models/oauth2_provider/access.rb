# Access info related to a resource owner using a specific
# client (block and statistics)

if defined?(Mongoid::Document)
  module Oauth2Provider
    class Access
      include Mongoid::Document
      include Mongoid::Timestamps

      field :client_uri                           # client identifier (internal)
      field :resource_owner_uri                   # resource owner identifier
      field :blocked, type: Time, default: nil    # authorization block (a user block a single client)

      embeds_many :daily_requests, class_name: 'Oauth2Provider::DailyRequest'           # daily requests (one record per day)
    end
  end
elsif defined?(ActiveRecord::Base)
  module Oauth2Provider
    class Access < ActiveRecord::Base
      set_table_name :oauth2_provider_accesses
      has_many :daily_requests
    end
  end
elsif defined?(MongoMapper::Document)
  raise NotImplementedError
elsif defined?(DataMapper::Resource)
  raise NotImplementedError
end


module Oauth2Provider
  class Access
    validates :client_uri, presence: true
    validates :resource_owner_uri, presence: true

    # Block the resource owner delegation to a specific client
    def block!
      self.blocked = Time.now
      self.save
      Token.block_access!(client_uri, resource_owner_uri)
      Authorization.block_access!(client_uri, resource_owner_uri)
    end

    # Unblock the resource owner delegation to a specific client
    def unblock!
      self.blocked = nil
      self.save
    end

    # Check if the status is or is not blocked
    def blocked?
      !self.blocked.nil?
    end

    # Increment the daily accesses
    def accessed!
      daily_requests_for(Time.now).increment!
    end

    # A daily requests record (there is one per day)
    #
    #   @params [String] time we want to find the requests record
    #   @return [DailyRequest] requests record
    def daily_requests_for(time = Time.now)
      find_or_create_daily_requests_for(time)
    end

    # Give back the last days in a friendly format.It is used to
    # generate graph for statistics
    def chart_days
      daily_requests = self.daily_requests.limit(10)
      days = daily_requests.map(&:created_at)
      days.map { |d| d.strftime("%b %e") }
    end

    # Give the number of accesses for the last days. It is used
    # to generate graph for statistics
    def chart_times
      access_times = self.daily_requests.limit(10)
      access_times.map(&:times)
    end


    private

    def find_or_create_daily_requests_for(time)
      daily_requests_for_time = self.daily_requests.find_day(time).first
      daily_requests_for_time = self.daily_requests.create(created_at: time) unless daily_requests_for_time
      return daily_requests_for_time
    end

    def daily_id(time)
      time.year + time.month + time.day
    end

  end
end
