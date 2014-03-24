module Modis
  module Persistence
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # :nodoc:
      def bootstrap_sti(parent, child)
        child.instance_eval do
        parent.instance_eval do
          class << self
              attr_accessor :sti_parent
            end
            attribute :type, :string
          end

          class << self
            delegate :attributes, to: :sti_parent
          end

          @sti_child = true
          @sti_parent = parent
        end
      end

      # :nodoc:
      def sti_child?
        @sti_child == true
      end

      def namespace
        return sti_parent.namespace if sti_child?
        return @namespace if @namespace
        @namespace = name.split('::').map(&:underscore).join(':')
      end

      def namespace=(value)
        @namespace = value
      end

      def absolute_namespace
        parts = [Modis.config.namespace, namespace]
        @absolute_namespace = parts.compact.join(':')
      end

      def key_for(id)
        "#{absolute_namespace}:#{id}"
      end

      def create(attrs)
        # run_callbacks :create do
          model = new(attrs)
          model.save
          model
        # end
      end

      def create!(attrs)
        # run_callbacks :create do
        model = new(attrs)
        model.save!
        model
        # end
      end
    end

    def persisted?
      true
    end

    def key
      new_record? ? nil : self.class.key_for(id)
    end

    def new_record?
      defined?(@new_record) ? @new_record : true
    end

    def save
      return false unless valid?
      future = nil
      set_id if new_record?

      self.class.transaction do
        callback = new_record? ? :update : :create
        run_callbacks callback do
          attrs = []
          attributes.each { |k, v| attrs << k << coerce_to_string(k, v) }
          future = Redis.current.hmset(self.class.key_for(id), attrs)
          track(id) if new_record?
        end
      end

      if future && future.value == 'OK'
        reset_changes
        @new_record = false
        true
      else
        false
      end
    end

    def save!
      raise RecordNotSaved unless save
    end

    def destroy
      self.class.transaction do
        run_callbacks :destroy do
          Redis.current.del(key)
          untrack(id)
        end
      end
    end

    protected

    def set_id
      self.id = Redis.current.incr("#{self.class.absolute_namespace}_id_seq")
    end

    def track(id)
      Redis.current.sadd(self.class.key_for(:all), id)
    end

    def untrack(id)
      Redis.current.srem(self.class.key_for(:all), id)
    end
  end
end
