module Rapns
  module Wpns
    class Notification < Rapns::Notification
      validates :uri, presence: true
      validates :uri, format: { with: /https?:\/\/[\S]+/ }
      validates :alert, presence: true

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

      def uri_is_valid?
        return (/https?:\/\/[\S]+/.match(uri) != nil)
      end
    end
  end
end
