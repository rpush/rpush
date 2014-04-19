module Modis
  module Attributes
    TYPES = [:string, :integer, :float, :timestamp, :boolean, :array, :hash]

    def self.included(base)
      base.extend ClassMethods

      base.instance_eval do
        bootstrap_attributes
      end
    end

    module ClassMethods
      def bootstrap_attributes
        class << self
          attr_accessor :attributes
        end

        self.attributes = {}

        attribute :id, :integer
      end

      def attribute(name, type = :string, options = {})
        name = name.to_s
        return if attributes.keys.include?(name)
        raise UnsupportedAttributeType.new(type) unless TYPES.include?(type)

        attributes[name] = options.update({ 'type' => type })
        define_attribute_methods [name]
        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            attributes['#{name}']
          end

          def #{name}=(value)
            value = coerce_to_type('#{name}', value)
            #{name}_will_change! unless value == attributes['#{name}']
            attributes['#{name}'] = value
          end
        EOS
      end
    end

    def attributes
      @attributes ||= Hash[self.class.attributes.keys.zip]
    end

    def assign_attributes(hash)
      hash.each do |k, v|
        setter = "#{k}="
        send(setter, v) if respond_to?(setter)
      end
    end

    protected

    def set_sti_type
      if self.class.sti_child?
        assign_attributes(type: self.class.name)
      end
    end

    def reset_changes
      @changed_attributes.clear if @changed_attributes
    end

    def apply_defaults
      defaults = {}
      self.class.attributes.each do |attribute, options|
        defaults[attribute] = options[:default] if options[:default]
      end
      assign_attributes(defaults)
    end

    def coerce_to_string(attribute, value)
      attribute = attribute.to_s
      return if value.blank?
      type = self.class.attributes[attribute]['type']
      if type == :array || type == :hash
        MultiJson.encode(value) if value
      elsif type == :timestamp
        value.iso8601
      else
        value.to_s
      end
    end

    def coerce_to_type(attribute, value)
      # TODO: allow an attribute to be set to nil
      return if value.blank?
      attribute = attribute.to_s
      type = self.class.attributes[attribute]['type']

      if type == :string
        value.to_s
      elsif type == :integer
        value.to_i
      elsif type == :float
        value.to_f
      elsif type == :timestamp
        return value if value.kind_of?(Time)
        Time.parse(value)
      elsif type == :boolean
        return true if [true, 'true'].include?(value)
        return false if [false, 'false'].include?(value)
        raise AttributeCoercionError.new("'#{value}' cannot be coerced to a :boolean.")
      elsif type == :array
        decode_json(value, Array, attribute)
      elsif type == :hash
        decode_json(value, Hash, attribute)
      else
        value
      end
    end

    def decode_json(value, type, attribute)
      return value if value.kind_of?(type)
      value = MultiJson.decode(value) if value.kind_of?(String)
      return value if value.kind_of?(type)
      raise AttributeCoercionError.new("Expected #{attribute} to be an #{type}, got #{value.class} instead.")
    end
  end
end
