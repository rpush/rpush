module Rpush
  module Proxy
    def configure_proxy(options)
      return unless (proxy_uri = Rpush.config.proxy_uri.presence)

      options.merge!(
        {
          proxy_host: proxy_uri.host,
          proxy_port: proxy_uri.port.presence,
          proxy_user: proxy_uri.user.presence,
          proxy_pass: proxy_uri.password.presence
        }.compact
      )
    end
  end
end
