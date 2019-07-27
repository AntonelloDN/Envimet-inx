module Envimet::EnvimetInx

  class EnvimetXml

    require "rexml/document"
    include REXML

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

      grid = preparation.get_value("grid")
      location = preparation.get_value("location")
      plant_2d = preparation.get_value("plant_2d")

      attribute_2d = {"type"=>"matrix-data", "dataI" => grid.other_info[:numX], "dataJ" => grid.other_info[:numY]}
      attribute_base = {"type"=>"sparematrix-3D", "dataI" =>  grid.other_info[:numX], "dataJ" => grid.other_info[:numY], "zlayers" => grid.other_info[:numZ]}
      attribute_3d_building = attribute_base.merge({"defaultValue" => "0"})
      attribute_3d_wall_db = attribute_base.merge({"defaultValue" => ""})
      attribute_3d_dem = attribute_base.merge({"defaultValue" => "0.00000"})

      doc = Document.new
      root = Element.new("ENVI-MET_Datafile")

      useTelescoping_grid, verticalStretch, startStretch, useSplitting, grid_Z = 0, 0, 0, 1, grid.other_info[:numZ] - 4

      if grid.other_info[:telescope] != 0
        useTelescoping_grid = 1
        verticalStretch = grid.other_info[:telescope]
        startStretch = grid.other_info[:startTelescopeHeigth]
        useSplitting = 0
        grid_Z = grid.other_info[:numZ]
      end

      terrain_empty_matrix = Grid.get_envimet_matrix(grid.base_matrix_2d(0)).delete_suffix(NEWLINE)
      soil_empty_matrix = Grid.get_envimet_matrix(grid.base_matrix_2d("000000")).delete_suffix(NEWLINE)

      header = {"filetype" => "INPX ENVI-met Area Input File", "version" => "401", "revisiondate" => Time.now, "remark" => "Created with Sketchup", "checksum" => "0", "encryptionlevel" => "0"}
      base_data = {"modelDescription" => "A brave new area", "modelAuthor" => " ", "modelcopyright" => "The creator or distributor is responsible for following Copyright Laws"}
      model_geometry = {"grids-I" => grid.other_info[:numX], "grids-J" => grid.other_info[:numY], "grids-Z" => grid_Z, "dx" => grid.dimX.to_m, "dy" => grid.dimY.to_m, "dz-base" => grid.dimZ.to_m, "useTelescoping_grid" => useTelescoping_grid, "useSplitting" => useSplitting, "verticalStretch" => verticalStretch, "startStretch" => startStretch, "has3DModel" => "1", "isFull3DDesign" => "1"}
      nesting_area = {"numberNestinggrids" => "3", "soilProfileA" => "0000LO", "soilProfileB" => "0000LO"}
      location_data = {"modelRotation" => "0.00000", "projectionSystem" => " ", "realworldLowerLeft_X" =>"0.00000", "realworldLowerLeft_Y" => "0.00000", "locationName" => location.name, "location_Longitude" => location.longitude, "location_Latitude" => location.latitude, "locationTimeZone_Name" => "UTC-0", "locationTimeZone_Longitude" => "15.00000"}
      default_settings = {"commonWallMaterial" => "000000", "commonRoofMaterial" => "000000"}
      buildings_2D = {"zTop" => preparation.get_value("top_matrix").delete_suffix(NEWLINE), "zBottom" => preparation.get_value("bottom_matrix").delete_suffix(NEWLINE), "buildingNr" => preparation.get_value("id_matrix").delete_suffix(NEWLINE), "fixedheight" => preparation.get_value("bottom_matrix").delete_suffix(NEWLINE)}
      simpleplants_2D = {"ID_plants1D" => plant_2d.delete_suffix(NEWLINE)}
      soils_2D = {"ID_soilprofile" => soil_empty_matrix}
      dem = {"terrainheight" => terrain_empty_matrix}
      model_geometry_3d = {"grids3D-I" => grid.other_info[:numX], "grids3D-J" => grid.other_info[:numY], "grids3D-K" => grid.other_info[:numZ]}
      buildings_3D = {"buildingFlagAndNr" => preparation.get_value("building_flag_and_nr").delete_suffix(NEWLINE)}
      dem_3D = {"terrainflag" => NEWLINE}
      wall_db = {"ID_wallDB" => preparation.get_value("db_matrix").delete_suffix(NEWLINE)}
      single_wall = {"ID_singlewallDB" => NEWLINE}
      green_wall = {"ID_GreeningDB" => NEWLINE}

      create_childs(root, "Header", header)
      create_childs(root, "baseData", base_data)
      create_childs(root, "modelGeometry", model_geometry)
      create_childs(root, "nestingArea", nesting_area)
      create_childs(root, "locationData", location_data)
      create_childs(root, "defaultSettings", default_settings)
      create_childs(root, "buildings2D", buildings_2D, attribute_2d)
      create_childs(root, "simpleplants2D", simpleplants_2D, attribute_2d)
      create_childs(root, "soils2D", soils_2D, attribute_2d)
      create_childs(root, "dem", dem, attribute_2d)
      create_childs(root, "modelGeometry3D", model_geometry_3d)
      create_childs(root, "buildings3D", buildings_3D, attribute_3d_building)
      create_childs(root, "dem3D", dem_3D, attribute_3d_dem)
      create_childs(root, "WallDB", wall_db, attribute_3d_wall_db)
      create_childs(root, "SingleWallDB", single_wall, attribute_3d_wall_db)
      create_childs(root, "GreeningDB", green_wall, attribute_3d_wall_db)

      doc << root

      doc
    end


    def write_xml(doc, full_path)

      out = ''
      formatter = Formatters::Pretty.new(0, true)
      formatter.compact = true
      formatter.write(doc, out)

      adaptXmlText(out)
      puts out

      # create a real file
      File.open(full_path, "w") do |file|
        file.write(out)
      end

    end

    private
    def adaptXmlText(text)
      text.gsub!("§", "\n")
      text.gsub!("\'", "\"")
    end

    def envimet_object_validation(preparation)
      preparation.get_value("grid").nil? || preparation.get_value("location").nil? || preparation.get_value("plant_2d").nil?
    end

  end

end
