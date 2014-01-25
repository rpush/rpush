module Rpush
  module Apns
    class App < Rpush::App
      validates :environment, :presence => true, :inclusion => { :in => %w(development production sandbox) }
      validates :certificate, :presence => true
      validate :certificate_has_matching_private_key

      def service_name
        'apns'
      end

      private

      def certificate_has_matching_private_key
        result = false
        if certificate.present?
          begin
            x509 = OpenSSL::X509::Certificate.new(certificate)
            pkey = OpenSSL::PKey::RSA.new(certificate, password)
            result = !x509.nil? && !pkey.nil?
          rescue OpenSSL::OpenSSLError
            errors.add :certificate, 'Certificate value must contain a certificate and a private key.'
          end
        end
        result
      end
    end
  end
end
