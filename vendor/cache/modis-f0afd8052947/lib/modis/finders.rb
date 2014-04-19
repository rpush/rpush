module Modis
  module Finders
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def find(id)
        record = attributes_for(id)
        model_class(record).new(record, new_record: false)
      end

      def all
        ids = Redis.current.smembers(key_for(:all))
        records = Redis.current.pipelined do
          ids.map { |id| Redis.current.hgetall(key_for(id)) }
        end
        records.map do |record|
          klass = model_class(record)
          klass.new(record, new_record: false)
        end
      end

      def attributes_for(id)
        if id.nil?
          raise RecordNotFound, "Couldn't find #{name} without an ID"
        end
        values = Redis.current.hgetall(key_for(id))
        unless values['id'].present?
          raise RecordNotFound, "Couldn't find #{name} with id=#{id}"
        end
        values
      end

      private

      def model_class(record)
        return self if record["type"].blank?
        return record["type"].constantize
      end
    end
  end
end
