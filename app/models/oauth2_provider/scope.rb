if defined?(Mongoid::Document)
  module Oauth2Provider
    class Scope
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name
      field :uri
      field :values, type: Array, default: []
    end
  end
elsif defined?(ActiveRecord::Base)
  module Oauth2Provider
    class Scope < ActiveRecord::Base
      set_table_name :oauth2_provider_scopes
      include Oauth2Provider::Document::ActiveRecordHelp
      before_save :sync_values_json
    end
  end
elsif defined?(MongoMapper::Document)
  raise NotImplementedError
elsif defined?(DataMapper::Resource)
  raise NotImplementedError
end

module Oauth2Provider
  class Scope
    include Document::Base

    attr_accessible :name

    validates :name, presence: true
    validates :values, presence: true
    validates :uri, url: true

    def normalize(val)
      separator = Oauth2Provider.settings["scope_separator"]
      val = val.split(separator)
    end

    def values_pretty
      separator = Oauth2Provider.settings["scope_separator"]
      values.join(separator)
    end

    class << self
      # Sync all scopes with the correct exploded scope when a
      # scope is modified (changed or removed)
      def sync_scopes_with_scope(scope)
        scopes_to_sync = any_in(scope: [scope])
        scopes_to_sync.each do |client|
          scope.values = Oauth2Provider.normalize_scope(scope.values)
          scope.save
        end
      end
    end
  end
end
