module Rapns
  class CertificateError < Exception; end

  module Daemon
    class Certificate
      def self.load(certificate_path)
        @certificate = read_certificate(certificate_path)
      end

      def self.certificate
        @certificate
      end

      protected

      def self.read_certificate(certificate_path)
        if !File.exists?(certificate_path)
          raise CertificateError, "#{certificate_path} does not exist. The certificate location can be configured in config/rapns/rapns.yml."
        else
          File.read(certificate_path)
        end
      end
    end
  end
end