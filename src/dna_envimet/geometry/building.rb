module Envimet
  module EnvimetInx
    module Geometry
      class Building
	  
	    DEFAULT_WALL_MATERIAL = "000000"
	    DEFAULT_ROOF_MATERIAL = "000000"
      
      @@count = 0
	    @@objects = []
		
	    attr_accessor :other_info
		  attr_reader :guid, :index, :name
		
      def initialize(name = " ", others = {})
      
	      @name = name
		  
		    values = {
            wall_material:DEFAULT_WALL_MATERIAL,
            roof_material:DEFAULT_ROOF_MATERIAL,
            green_wall:nil,
            green_roof:nil
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
		  "<tr><th>ID</th><th>NAME</th><th>WALL_MATERIAL</th><th>ROOF_MATERIAL</th></tr><tr><th>#{index}</th><th>#{name}</th><th>#{other_info[:wall_material]}|#{other_info[:green_wall]}</th><th>#{other_info[:roof_material]}|#{other_info[:green_roof]}</th></tr>"
	    end
		
		  def self.set_max_count(objects)
		    index = objects.map {|obj| obj.get_count}
		    @@count = index.max + 1
		  end
	    
	    def self.get_count
	      @@count
	    end
	    
	    # class method
	    def self.get_by_group_guid(guid)
	      building = @@objects.select { |bld| guid == bld.guid }
	  	  building
        end
	    
	    def self.get_existing_guid
	      existing_guid = @@objects.map { |build| build.guid }
	  	  existing_guid
	    end
		
	    def self.delete_by_group_guid(guid)
	      @@objects.delete_if { |bld| guid == bld.guid }
        end
	    
	    def self.add_buildings(building)
	      @@objects << building if building.is_a?(Building) && !building.guid.nil?
	    end
	    
	    def self.get_buildings
	      @@objects
	    end
		
		  def self.set_index(objects)
		    index_list = objects.grep(Geometry::Building).map {|obj| obj.index}
		    unless index_list.empty?
	          @@count = index_list.max
		    end
		  end
		
		  def self.reset
		    @@objects = []
		    @@count = 0
		  end
      
      end # end Building
	  end # end Geometry
  end # end EnvimetInx
end # end Envimet