module Envimet
  module EnvimetInx
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

      def reset
        @objects = {}
      end
    end # end Preparation
  end # end EnvimetInx
end # end Envimet
