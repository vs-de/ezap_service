module Ezap::Service::Base
  class ServiceObject
    def self.inherited base
      service_class = Ezap::Service::Base.container_list.find do |klass|
        base.to_s.split('::').reverse.any?{|p|klass.to_s.split('::').reverse.include?(p)}
      end
      raise "error: No service-class found in any parent module of #{base}" unless service_class
      service_class._add_service_object_class base
    end

    def initialize *args
      
    end

    #def self.create service, *args
    #  service._add_service_object(new(*args))
    #end
    
  end
end
