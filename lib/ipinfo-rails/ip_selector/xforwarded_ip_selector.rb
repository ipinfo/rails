# frozen_string_literal: true
require 'ipinfo-rails/ip_selector/ip_selector_interface'

class XForwardedIPSelector
    include IPSelectorInterface

    def initialize(request)
        @request = request
    end
    
    def get_ip()
        x_forwarded = @request.env['HTTP_X_FORWARDED_FOR']
        if !x_forwarded || x_forwarded.empty?
            return @request.ip
        else
            return x_forwarded.split(',' , -1)[0]
        end
    end
end
