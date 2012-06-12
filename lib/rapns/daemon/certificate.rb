module Rapns
  class CertificateError < StandardError; end

  module Daemon
    class Certificate
      def self.read(certificate_path)
        if !File.exists?(certificate_path)
          raise CertificateError, "#{certificate_path} does not exist."
        else
          File.read(certificate_path)
        end
      end
    end
  end
end