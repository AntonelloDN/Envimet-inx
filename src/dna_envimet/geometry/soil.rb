module Envimet
  module EnvimetInx
    module Geometry
      class Soil
	  
	      DEFAULT_SOIL_MATERIAL = "0100ST"
		    BASE_SOIL_MATERIAL = "000000"
        
        @@count = 0
	      @@objects = []
		  
	      attr_accessor :other_info
		    attr_reader :guid, :index, :name
		
		
        def initialize(name = " ", others = {})
      
	        @name = name
		  
		      values = {
            material:DEFAULT_SOIL_MATERIAL
          }

          values.merge!(others)
		      @other_info = values
		  
	  	    @guid = nil
	        @@count += 1
	    
          @index = @@count
      
        end
	    
	      def guid=(value)
	        @guid = value if value
	      end
	      
	      def to_s
		      "<tr><th>ID</th><th>NAME</th><th>MATERIAL</th></tr><tr><th>#{index}</th><th>#{name}</th><th>#{other_info[:material]}</th></tr>"
	      end
	      
	      def self.get_count
	        @@count
	      end
		
	      # class method
	      def self.get_by_group_guid(guid)
	        soil = @@objects.select { |sol| guid == sol.guid }
	  	    soil
        end
	    
	      def self.get_existing_guid
	        existing_guid = @@objects.map { |soil| soil.guid }
	  	    existing_guid
	      end
		
	      def self.delete_by_group_guid(guid)
	        @@objects.delete_if { |sol| guid == sol.guid }
        end
	    
	      def self.add_soils(soil)
	        @@objects << soil if soil.is_a?(Soil) && !soil.guid.nil?
	      end
	    
	      def self.get_soils
	        @@objects
	      end
      
		    def self.set_index(objects)
		      index_list = objects.grep(Geometry::Soil).map {|obj| obj.index}
		      unless index_list.empty?
	            @@count = index_list.max
		      end
		    end
		
		    def self.reset
		      @@objects = []
		      @@count = 0
		    end
	  
      end # end Soil
	  end # end Geometry
  end # end EnvimetInx
end # end Envimet