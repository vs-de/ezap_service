#####
# Copyright 2013, Valentin Schulte, Leipzig
# This File is part of Ezap.
# It is shared to be part of wecuddle from Lailos Group GmbH, Leipzig.
# Before changing or using this code, you have to accept the Ezap License in the Ezap_LICENSE.txt file 
# included in the package or repository received by obtaining this file.
#####
class SimpleLogCore
  
  def initialize ret
    @buffer = ''
    @ret = ret
  end

  def write arg
    @buffer << arg
  end

  def close
    @ret.log_ready(self) if @ret.respond_to?(:log_ready)
  end

  def read
    @buffer
  end
end

class WorkLoggerScheme
  attr_reader :log_object

  def initialize obj, _tree={}, indent='' # &recv_block
    @indent = indent
    @log_object = obj.is_a?(LogObject) ? obj : LogObject.new(obj)
    @tree = _tree
    #super(@log_object)
  end

  #def log lvl, msg, name, &blk
  #  "log_called #{super(lvl, msg, name) &blk}"
  #end

  def processing obj
    handle_transitions = obj.respond_to?(:status)
    info "processing #{obj.class} #{obj.id}"
    key = "#{obj.class.to_s.underscore}_#{obj.id}".to_sym
    hsh = (@tree[key] ||= {})
    next_log = self.class.new(@log_object, hsh, @indent+'->')
    if handle_transitions
      init_state = obj.status
      yield next_log
      final_state = obj.status
      (hsh[:transitions] ||= {}).merge!(init_state => final_state)
    else
      yield next_log
    end
  end

  def transition sub, cmd
    transisions = (@tree[:transitions] ||= {})
  end

  def close
    @tree
  end

end

class WorkLogger
  DEFAULT_LEVELS = [:debug, :info, :warn, :error, :fatal]
  def initialize obj, levels = DEFAULT_LEVELS
    levels.each do |lvl|
      define_singleton_method(lvl) do |arg|
        obj.write(obj, arg)
      end
    end
  end
end


