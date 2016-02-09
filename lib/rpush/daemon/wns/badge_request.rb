module Rpush
  module Daemon
    module Wns
      class BadgeRequest
        def self.create(notification, access_token)
          body = BadgeRequestPayload.new(notification).to_xml
          uri  = URI.parse(notification.uri)
          post = Net::HTTP::Post.new(
            uri.request_uri,
            "Content-Length" => body.length.to_s,
            "Content-Type" => "text/xml",
            "X-WNS-Type" => "wns/badge",
            "X-WNS-RequestForStatus" => "true",
            "Authorization" => "Bearer #{access_token}"
          )
          post.body = body
          post
        end
      end

      class BadgeRequestPayload
        def initialize(notification)
          @badge = notification.badge || 0
        end

        def to_xml
          "<badge value=\"#{@badge}\"/>"
        end
      end
    end
  end
end
