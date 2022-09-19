# frozen_string_literal: true
require 'ipinfo-rails/ipselector/ipselector_interface'

class XForwardedIPSelector
    include IPSelectorInterface
    def initialize(request)
        @request = request
    end
    
    def get_ip()
        return @request.env['HTTP_X_FORWARDED_FOR']
    end

end
