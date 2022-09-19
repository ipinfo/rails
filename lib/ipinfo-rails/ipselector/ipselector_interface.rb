# frozen_string_literal: true
module IPSelectorInterface
    class InterfaceNotImplemented < StandardError; end
    def get_ip()
        raise InterfaceNotImplemented
    end
end
