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

    def save(args={})
      begin
        create_or_update(args)
      rescue Modis::RecordInvalid
        false
      end
    end

    def save!(args={})
      create_or_update(args) || (raise RecordNotSaved)
    end

    def destroy
      self.class.transaction do
        run_callbacks :destroy do
          Redis.current.del(key)
          untrack(id)
        end
      end
    end

    def reload
      new_attributes = self.class.attributes_for(id)
      initialize(new_attributes)
      self
    end

    def update_attribute(name, value)
      assign_attributes(name => value)
      save(validate: false)
    end

    def update_attributes(attrs)
      assign_attributes(attrs)
      save
    end

    def update_attributes!(attrs)
      assign_attributes(attrs)
      save!
    end

    protected

    def create_or_update(args={})
      skip_validate = args.key?(:validate) && args[:validate] == false
      if !skip_validate && !valid?
        raise Modis::RecordInvalid, errors.full_messages.join(', ')
      end

      future = nil
      set_id if new_record?

      self.class.transaction do
        run_callbacks :save do
          callback = new_record? ? :create : :update
          run_callbacks callback do
            attrs = []
            attributes.each { |k, v| attrs << k << coerce_to_string(k, v) }
            future = Redis.current.hmset(self.class.key_for(id), attrs)
            track(id) if new_record?
          end
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
