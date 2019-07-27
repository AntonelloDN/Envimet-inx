module Envimet::EnvimetInx

  class Preparation

    attr_reader :objects

    def initialize
      @objects = {}
    end

    def add_value(name, value)
      objects[name] = value
    end

    def get_value(name)
      objects[name]
    end

  end

end
