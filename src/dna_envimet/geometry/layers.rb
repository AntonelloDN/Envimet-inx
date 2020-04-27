module Envimet
  module EnvimetInx
    
    module SkpLayers
	  
	    GRID = "grid_envimet"
	    IN_BUILDING = "in_building_envimet"
	    IN_PLANT2D = "in_plant2d_envimet"
	    IN_PLANT3D = "in_plant3d_envimet"
	    IN_SOIL = "in_soil_envimet"
	    IN_TERRAIN = "in_terrain_envimet"
	    IN_RECEPTOR = "in_receptor_envimet"
	    IN_SOURCE = "in_source_envimet"
	    
	    OUT_BUILDING = "out_building_envimet"
	    OUT_PLANT2D = "out_plant2d_envimet"
	    OUT_PLANT3D = "out_plant3d_envimet"
	    OUT_SOIL = "out_soil_envimet"
	    OUT_TERRAIN = "out_terrain_envimet"
	    OUT_RECEPTOR = "out_receptor_envimet"
	    OUT_SOURCE = "out_source_envimet"
	    
	    GRID_COLOR = Sketchup::Color.new(23, 32, 42)
	    BUILDING_COLOR = Sketchup::Color.new(247, 220, 111)
	    PLANT2D_COLOR = Sketchup::Color.new(46, 204, 113)
	    PLANT3D_COLOR = Sketchup::Color.new(39, 174, 96)
	    SOIL_COLOR = Sketchup::Color.new(115, 198, 182)
	    TERRAIN_COLOR = Sketchup::Color.new(250, 215, 160)
	    RECEPTOR_COLOR = Sketchup::Color.new(241, 148, 138)
	    SOURCE_COLOR = Sketchup::Color.new(52, 73, 94)
	  
    end # end SkpLayers
	
	  module SkpMaterial
	  
	    GRID_MAT_NAME = "ENVI-Met-Grid"
	    BUILDING_MAT_NAME = "ENVI-Met-Bulding"
	    PLANT2D_MAT_NAME = "ENVI-Met-Plant2d"
	    PLANT3D_MAT_NAME = "ENVI-Met-Plant3d"
	    SOIL_MAT_NAME = "ENVI-Met-Soil"
	    TERRAIN_MAT_NAME = "ENVI-Met-Terrain"
	    RECEPTOR_MAT_NAME = "ENVI-Met-Receptor"
	    SOURCE_MAT_NAME = "ENVI-Met-Source"
	    
	    GRID_PATH = "res/texture/grid.png"
	    BUILDING_PATH = "res/texture/building.png"
	    PLANT2D_PATH = "res/texture/plant2d.png"
	    PLANT3D_PATH = "res/texture/plant3d.png"
	    SOIL_PATH = "res/texture/soil.png"
	    TERRAIN_PATH = "res/texture/terrain.png"
	    RECEPTOR_PATH = "res/texture/receptor.png"
	    SOURCE_PATH = "res/texture/source.png"
	  
	  
	    def self.create_material(name, path)
	    
	      model = Sketchup.active_model
        materials = model.materials
        material = materials.add(name)
        material.color = nil
        material.texture = File.join(PLUGIN_DIR, path)
	      material.texture.size = 5.m
		  
	    end
	  
		end # end SkpMaterial
		
  end # end EnvimetInx
end # end Envimet
