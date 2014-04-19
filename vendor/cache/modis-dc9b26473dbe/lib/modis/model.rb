module Modis
  module Model
    def self.included(base)
      base.instance_eval do
        include ActiveModel::Dirty
        include ActiveModel::Validations
        include ActiveModel::Serialization

        extend ActiveModel::Naming
        extend ActiveModel::Callbacks

        define_model_callbacks :save
        define_model_callbacks :create
        define_model_callbacks :update
        define_model_callbacks :destroy

        include Modis::Errors
        include Modis::Transaction
        include Modis::Persistence
        include Modis::Finders
        include Modis::Attributes

        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def inherited(child)
        super
        bootstrap_sti(self, child)
      end
    end

    def initialize(record=nil, options={})
      set_sti_type
      apply_defaults
      assign_attributes(record.symbolize_keys) if record
      reset_changes

       if options.key?(:new_record)
        instance_variable_set('@new_record', options[:new_record])
      end
    end

    def ==(other)
      super || other.instance_of?(self.class) && id.present? && other.id == id
    end
    alias :eql? :==
  end
end
