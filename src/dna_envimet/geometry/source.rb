module Envimet
  module EnvimetInx
    module Geometry
      class Source
	  
	    DEFAULT_SOURCE_MATERIAL = "0000FT"
      
        @@count = 0
	    @@objects = []
		
	    attr_accessor :other_info
		attr_reader :guid, :index, :name
		
		
        def initialize(name = " ", others = {})
      
	      @name = name
		  
		  values = {
            material:DEFAULT_SOURCE_MATERIAL
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
	      source = @@objects.select { |sor| guid == sor.guid }
	  	  source
        end
	    
	    def self.get_existing_guid
	      existing_guid = @@objects.map { |source| source.guid }
	  	  existing_guid
	    end
		
	    def self.delete_by_group_guid(guid)
	      @@objects.delete_if { |sor| guid == sor.guid }
        end
	    
	    def self.add_sources(source)
	      @@objects << source if source.is_a?(Source) && !source.guid.nil?
	    end
	    
	    def self.get_sources
	      @@objects
	    end
		
		def self.set_index(objects)
		  index_list = objects.grep(Geometry::Source).map {|obj| obj.index}
		  unless index_list.empty?
	        @@count = index_list.max
		  end
		end
		
		def self.reset
		  @@objects = []
		  @@count = 0
		end
      
      end # end Source
	end # end Geometry
  end # end EnvimetInx
end # end Envimet