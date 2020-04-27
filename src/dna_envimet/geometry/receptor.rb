module Envimet
  module EnvimetInx
    module Geometry
      class Receptor
	    
	    @@objects = []
		
	    attr_accessor :other_info
		attr_reader :guid, :name
		
        def initialize(name = " ", others = {})
		
		  values = {}
		  values.merge!(others)
      	  
		  @other_info = values
	      @name = name
	  	  @guid = nil
      
        end
	    
	    def guid=(value)
	      @guid = value if value
	    end
	    
	    def to_s
		  "<tr><th>NAME</th></tr><tr><th>#{name}</th></tr>"
	    end
	    
	    def self.get_count
	      @@count
	    end
	    
	    # class method
	    def self.get_by_group_guid(guid)
	      receptor = @@objects.select { |rcp| guid == rcp.guid }
	  	  receptor
        end
	    
	    def self.get_existing_guid
	      existing_guid = @@objects.map { |receptor| receptor.guid }
	  	  existing_guid
	    end
		
	    def self.delete_by_group_guid(guid)
	      @@objects.delete_if { |rcp| guid == rcp.guid }
        end
	    
	    def self.add_receptors(receptor)
	      @@objects << receptor if receptor.is_a?(Receptor) && !receptor.guid.nil?
	    end
	    
	    def self.get_receptors
	      @@objects
	    end
		
		def self.reset
		  @@objects = []
		  @@count = 0
		end
      
      end # end Receptor
	end # end Geometry
  end # end EnvimetInx
end # end Envimet