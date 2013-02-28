module Ezap
  class Config
    @@hsh = {
      root: EZAP_ROOT
    }
    @@hsh[:config_file] = File.join(@@hsh[:root], CFG_PATH, CFG_FILE_NAME)
    @@hsh.merge!(YAML.load_file(@@hsh[:config_file]).symbolize_keys_rec!)
    
    def method_missing name
      @@hsh[name] || raise("key #{name} is not in config")
    end

    def to_hash
      @@hsh.clone
    end
  end
end
