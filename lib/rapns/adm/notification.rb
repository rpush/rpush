module Rapns
  module Adm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true
      validates_with Rapns::Adm::DataValidator
      validates_with Rapns::Adm::PayloadDataSizeValidator

      def registration_ids=(ids)
        ids = [ids] if ids && !ids.is_a?(Array)
        super
      end

      def as_json
        json = {
          'data' => data
        }

        if collapse_key
          json['consolidationKey'] = collapse_key
        end
        
        # number of seconds before message is expired
        if expiry
          json['expiresAfter'] = expiry
        end

        json
      end

      def payload_data_size
        multi_json_dump(as_json['data']).bytesize
      end
      
      # Computes MD5 checksum of the 'data' parameter as per the algorithm detailed in the ADM documentation.
      # Returns:
      #   MD5 checksum of key/value pairs within data.
      def calculate_checksum
          retval = ""
          utf8_data = {}
          utf8_keys = []

          # Converting data to UTF-8.
          data.keys.each do |key|
            utf8_keys.push(key.encode('utf-8'))
            utf8_data[key.encode('utf-8')] = data[key].encode('utf-8')
          end

          # UTF-8 sorting of the keys.
          utf8_keys.sort!
          # Concatenating the series of key-value pairs.
          utf8_string = utf8_keys.collect {|key| "#{key}:#{utf8_data[key]}" }.join(',')
          # Computing MD5 as per RFC 1321.
          md5 = Digest::MD5.digest(utf8_string)
          # Base 64 encoding.
          retval = Base64.encode64(md5)

          # puts "MD5: #{md5}, BASE64 ENCODED: #{retval}"
          
          retval
        end
    end
  end
end
