module Envimet
  module EnvimetInx
    module Geometry
      class Plant2d
	  
	    DEFAULT_PLANT2D_MATERIAL = "0100XX"
      
        @@count = 0
	    @@objects = []
		
	    attr_accessor :other_info
		attr_reader :guid, :index, :name
		
		
        def initialize(name = " ", others = {})
      
	      @name = name
		  
		  values = {
            material:DEFAULT_PLANT2D_MATERIAL
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
	      plant = @@objects.select { |plt| guid == plt.guid }
	  	  plant
        end
	    
	    def self.get_existing_guid
	      existing_guid = @@objects.map { |plant| plant.guid }
	  	  existing_guid
	    end
		
	    def self.delete_by_group_guid(guid)
	      @@objects.delete_if { |plt| guid == plt.guid }
        end
	    
	    def self.add_plants(plant)
	      @@objects << plant if plant.is_a?(Plant2d) && !plant.guid.nil?
	    end
	    
	    def self.get_plants
	      @@objects
	    end
		
		def self.set_index(objects)
		  index_list = objects.grep(Geometry::Plant2d).map {|obj| obj.index}
		  unless index_list.empty?
	        @@count = index_list.max
		  end
		end
		
		def self.reset
		  @@objects = []
		  @@count = 0
		end
	  
      end # end Plant2d
	end # end Geometry
  end # end EnvimetInx
end # end Envimet