module Envimet
  module EnvimetInx
    module Serializer
	  
      def self.read_file(binary)
	      objects = Marshal::load(File.binread(binary))
		    objects
      end
	  
	    def self.write_file(path, objects)
	      File.open(path, "wb") do |file|
		      file.write(Marshal::dump(objects))
		    end
	    end
      
    end # end Serializer
  end # end EnvimetInx
end # end Envimet
