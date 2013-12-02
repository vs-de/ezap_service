#####
# Copyright 2013, Valentin Schulte, Leipzig, Germany
# This file is part of Ezap.
# Ezap is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 3 
# as published by the Free Software Foundation.
# You should have received a copy of the GNU General Public License
# in the file COPYING along with Ezap. If not, see <http://www.gnu.org/licenses/>.
#####

module Ezap::Service::Immediate
  #include Ezap::Service::Base

  def self.included base
    base.send(:include, Ezap::Service::Base)
    
    base.instance_eval do
      base.const_set('Dispatcher', Class.new(base.const_get('CoreDispatcher')))
      def self.method_added m
        const_get('Dispatcher').send(:define_method, m) do
          {reply: service.send(m)}
        end
      end
    end
  end

end
