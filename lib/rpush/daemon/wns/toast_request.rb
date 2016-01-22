module Rpush
  module Daemon
    module Wns
      class ToastRequest
        def self.create(notification, access_token)
          body = ToastRequestPayload.new(notification).to_xml
          uri  = URI.parse(notification.uri)
          post = Net::HTTP::Post.new(
            uri.request_uri,
            "Content-Length" => body.length.to_s,
            "Content-Type" => "text/xml",
            "X-WNS-Type" => "wns/toast",
            "X-WNS-RequestForStatus" => "true",
            "Authorization" => "Bearer #{access_token}"
          )
          post.body = body
          post
        end
      end

      class ToastRequestPayload
        def initialize(notification)
          @title = notification.data['title'] || ''
          @body = notification.data['body'] || ''
        end

        def to_xml
          "<toast>
            <visual version='1' lang='en-US'>
              <binding template='ToastText02'>
                <text id='1'>#{CleanParamString.clean(@title)}</text>
                <text id='2'>#{CleanParamString.clean(@body)}</text>
              </binding>
            </visual>
          </toast>"
        end
      end

      class CleanParamString
        def self.clean(string)
          string.gsub(/&/, "&amp;").gsub(/</, "&lt;") \
            .gsub(/>/, "&gt;").gsub(/'/, "&apos;").gsub(/"/, "&quot;")
        end
      end
    end
  end
end
