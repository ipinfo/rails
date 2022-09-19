# frozen_string_literal: true
require 'ipinfo-rails/ipselector/ipselector_interface'

class DefaultIPSelector
    include IPSelectorInterface
    def initialize(request)
        @request = request
    end
    
    def get_ip()
        return @request.ip
    end

end