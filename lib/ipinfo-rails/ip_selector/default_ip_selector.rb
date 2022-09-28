# frozen_string_literal: true
require 'ipinfo-rails/ip_selector/ip_selector_interface'

class DefaultIPSelector
    include IPSelectorInterface

    def initialize(request)
        @request = request
    end
    
    def get_ip()
        return @request.ip
    end
end
