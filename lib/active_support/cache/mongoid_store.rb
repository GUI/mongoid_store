require 'mongoid'
require 'active_support'

module ActiveSupport
  module Cache
    class MongoidStore < Store
      attr_reader :collection_name

      def initialize(options = {})
        @collection_name = options[:collection] || :cache
        options[:expires_in] ||= 1.hour
        super(options)
      end

      def clear(options = nil)
        collection.find.remove_all
      end

      def cleanup(options = nil)
        options = merged_options(options)
        collection.find(expires_at: {'$lt' => Time.now.utc.to_i}).remove_all
      end

      def delete_matched(matcher, options = nil)
        options = merged_options(options)
        collection.find(_id: key_matcher(matcher, options)).remove_all
      end

      protected

      def write_entry(key, entry, options)
        collection.find(_id: key).upsert(_id: key, value: binary_for(entry.value), expires_at: entry.expires_at.to_i, created_at: Time.now.utc.to_i)
      end

      def read_entry(key, options = nil)
        document = collection.find(_id: key, expires_at: {'$gt' => Time.now.utc.to_i}).first
        ActiveSupport::Cache::Entry.create(value_for(document['value']), document['created_at']) if document
      end

      def delete_entry(key, options = nil)
        collection.find(_id: key).remove
      end

      private

      def binary_for(value)
        Moped::BSON::Binary.new(:generic, value.to_s.force_encoding('binary'))
      end

      def value_for(binary)
        binary.to_s
      end

      def collection
        Mongoid.session(:default)[collection_name]
      end
    end
  end
end
