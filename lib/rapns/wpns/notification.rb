module Rapns
  module Wpns
    class Notification < Rapns::Notification
      validates :uri, :presence => true
      validates_with Rapns::Wpns::DataValidator

      def data=(attrs)
        return unless attrs
        raise ArgumentError, "must be a Hash" if !attrs.is_a?(Hash)
        super attrs.merge(data || {})
      end

      def as_json
        json = {
          'message' => alert,
          'uri'     => uri
        }

        if collapse_key
          json['consolidationKey'] = collapse_key
        end

        json
      end

      def uri_is_valid?()
        return (/https?:\/\/[\S]+/.match(uri) != nil)
      end
    end
  end
end
