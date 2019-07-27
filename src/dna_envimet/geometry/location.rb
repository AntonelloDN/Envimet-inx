module Envimet::EnvimetInx

  class Location

    attr_reader :name, :latitude, :longitude

    def initialize(name, latitude = "0.000000", longitude = "0.000000")

      @name = name
      @latitude = latitude
      @longitude = longitude

    end

  end

end
