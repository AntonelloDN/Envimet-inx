module Envimet
  module EnvimetInx
    module IO
      class Inx
        
        require "rexml/document"
        include REXML
        
		    ONE = 1
        NEWLINE = "§" # this because inx is not a standard xml
        
        def create_childs(root, element, childs, attributes={})
        
          base_element = Element.new(element)
        
          childs.each do |k, v|
            child_element = Element.new(k)
            child_element.text = v
            base_element.add_element(child_element, attributes)
          end
        
          root << base_element
        
        end
      
      
        def create_xml(preparation)
        
          if envimet_object_validation(preparation)
            return
          end
		  
		      if envimet_location_validation(preparation)
            return
          end
		  
		      # get envimet objects
          grid = preparation.get_value("grid").first
          location = preparation.get_value("location")
          building = preparation.get_value("building")
          plant3d = preparation.get_value("plant3d")
          receptor = preparation.get_value("receptor")
		  
		      # get envimet matrix
          top_matrix = preparation.get_value("top_matrix")
          bottom_matrix = preparation.get_value("bottom_matrix")
          id_matrix = preparation.get_value("id_matrix")
          soil_matrix = preparation.get_value("soil_matrix")
          plant2d_matrix = preparation.get_value("plant2d_matrix")
          terrain_matrix = preparation.get_value("terrain_matrix")
          source_matrix = preparation.get_value("source_matrix")
		  
		      # set attribute
		      num_x = grid.other_info[:numX] + 1
		      num_y = grid.other_info[:numY] + 1
		      num_z = grid.other_info[:numZ_cells]
          attribute_2d = {"type"=>"matrix-data", "dataI" => num_x, "dataJ" => num_y}
		  
          doc = Document.new
          root = Element.new("ENVI-MET_Datafile")
		  
          useTelescoping_grid, verticalStretch, startStretch, useSplitting, grid_Z = 0, 0, 0, 1, num_z

          if grid.other_info[:grid_type] == :telescope
            useTelescoping_grid = 1
            verticalStretch = grid.other_info[:telescope]
            startStretch = grid.other_info[:start_telescope_heigth]
            useSplitting = 0
		      elsif grid.other_info[:grid_type] == :combined
            useTelescoping_grid = 1
            verticalStretch = grid.other_info[:telescope]
            startStretch = grid.other_info[:start_telescope_heigth]
            useSplitting = 1
          end
        
          header = {"filetype" => "INPX ENVI-met Area Input File", "version" => "440", "revisiondate" => Time.now, "remark" => "Created with Sketchup", "checksum" => "6104088", "encryptionlevel" => "0"}
          base_data = {"modelDescription" => "A brave new area", "modelAuthor" => " ", "modelcopyright" => "The creator or distributor is responsible for following Copyright Laws"}
          model_geometry = {"grids-I" => num_x, "grids-J" => num_y, "grids-Z" => grid_Z, "dx" => grid.dimX.to_m, "dy" => grid.dimY.to_m, "dz-base" => grid.dimZ.to_m, "useTelescoping_grid" => useTelescoping_grid, "useSplitting" => useSplitting, "verticalStretch" => verticalStretch, "startStretch" => startStretch, "has3DModel" => "0", "isFull3DDesign" => "0"}
          nesting_area = {"numberNestinggrids" => "0", "soilProfileA" => "000000", "soilProfileB" => "000000"}
          location_data = {"modelRotation" => location.rotation, "projectionSystem" => "GCS_WGS_1984 (lat/long)", "realworldLowerLeft_X" =>"0.00000", "realworldLowerLeft_Y" => "0.00000", "locationName" => location.name, "location_Longitude" => location.longitude, "location_Latitude" => location.latitude, "locationTimeZone_Name" => location.utc, "locationTimeZone_Longitude" => "15.00000"}
          default_settings = {"commonWallMaterial" => Geometry::Building::DEFAULT_WALL_MATERIAL, "commonRoofMaterial" => Geometry::Building::DEFAULT_ROOF_MATERIAL}
          buildings_2D = {"zTop" => top_matrix, "zBottom" => bottom_matrix, "buildingNr" => id_matrix, "fixedheight" => preparation.get_value("zero_matrix")}
          simpleplants_2D = {"ID_plants1D" => plant2d_matrix} if plant2d_matrix != NEWLINE
          soils_2D = {"ID_soilprofile" => soil_matrix}
          dem = {"terrainheight" => terrain_matrix}
          source_2D = {"ID_sources" => source_matrix} if source_matrix != NEWLINE
		  
          create_childs(root, "Header", header)
          create_childs(root, "baseData", base_data)
          create_childs(root, "modelGeometry", model_geometry)
          create_childs(root, "nestingArea", nesting_area)
          create_childs(root, "locationData", location_data)
          create_childs(root, "defaultSettings", default_settings)
          create_childs(root, "buildings2D", buildings_2D, attribute_2d)
		  
          create_childs(root, "simpleplants2D", simpleplants_2D, attribute_2d) if plant2d_matrix != NEWLINE
		  
		      unless plant3d == []
		        plant3d.each do |plt_group|
		          plt_group.other_info[:pixels].each do |pix|
		            plant3d_info = {"rootcell_i" => pix.i, "rootcell_j" => pix.j, "rootcell_k" => 0, "plantID" => plt_group.other_info[:material], "name" => plt_group.name, "observe" => 0}
		            create_childs(root, "3Dplants", plant3d_info)
			      end
		        end
		      end
		      
		      unless receptor == []
		        receptor.each do |rec_group|
		          rec_group.other_info[:pixels].each do |pix|
		            receptors_info = {"cell_i" => pix.i, "cell_j" => pix.j, "name" => rec_group.name + pix.i.to_s +  pix.j.to_s}
		            create_childs(root, "Receptors", receptors_info)
			      end
		        end
		      end
		  
          create_childs(root, "soils2D", soils_2D, attribute_2d)
          create_childs(root, "dem", dem, attribute_2d)
          create_childs(root, "sources2D", source_2D, attribute_2d) if source_matrix != NEWLINE
		  
		      unless building == []
		        building.each do |bld|
		          building_info = {"BuildingInternalNr" => bld.index, "BuildingName" => bld.name, "BuildingWallMaterial" => bld.other_info[:wall_material], "BuildingRoofMaterial" => bld.other_info[:roof_material], "BuildingFacadeGreening" => bld.other_info[:green_wall], "BuildingRoofGreening" => bld.other_info[:green_roof]}
		          create_childs(root, "Buildinginfo", building_info)
		        end
		      end
		  
          doc << root
        
          doc
        end
        
        
        def write_xml(doc, full_path)
        
          out = ''
          formatter = Formatters::Pretty.new(0, true)
          formatter.compact = true
          formatter.write(doc, out)
        
          adapt_xml_text(out)
        
		      temp = out.split("\n").reject {|c| c.empty? } # this because inx is not a standard xml
		  
          # create file
          File.open(full_path, "w") do |file|
            file.write(temp.join("\n"))
          end
		  
		      UI.messagebox("INX file written.")
		  
        end
        
        private
        def adapt_xml_text(text)
          text.gsub!("§", "\n")
          text.gsub!("\'", "\"")
        end
        
        def envimet_object_validation(preparation)
          preparation.get_value("grid").nil? || preparation.get_value("location").nil?
        end
		
		    def envimet_location_validation(preparation)
          preparation.get_value("location").latitude.nil?
        end
      
      end # end Inx
	  end # end IO
  end # end EnvimetInx
end # end Envimet
