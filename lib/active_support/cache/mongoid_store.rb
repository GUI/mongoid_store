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
        collection.find(_id: key).upsert(_id: key, value: serialize(entry.value), expires_at: entry.expires_at.to_i, created_at: Time.now.utc.to_i)
      end

      def read_entry(key, options = nil)
        document = collection.find(_id: key, expires_at: {'$gt' => Time.now.utc.to_i}).first
        if document
          value = deserialize(document['value'])
          created_at = document['created_at']
          ActiveSupport::Cache::Entry.create(value, created_at)
        end
      end

      def delete_entry(key, options = nil)
        collection.find(_id: key).remove
      end

      private

      def serialize(object)
        string = Marshal.dump(object)
        binary = Moped::BSON::Binary.new(:generic, string)
      end

      def deserialize(binary)
        string = binary.to_s
        object = Marshal.load(string)
      end

      def collection
        Mongoid.session(:default)[collection_name]
      end
    end
  end
end
