module Envimet
  module EnvimetInx
    class EnvimetAppObserver < Sketchup::AppObserver
      def onNewModel(model)
        EnvimetInx.reset_all
      end

      def onOpenModel(model)
        EnvimetInx.reset_all
        EnvimetInx.is_envimet_model_active?
      end
    end

    def self.reset_all
      @@preparation.reset
      Geometry::Building.reset
      Geometry::Plant2d.reset
      Geometry::Plant3d.reset
      Geometry::Soil.reset
      Geometry::Terrain.reset
      Geometry::Source.reset

      @@preparation.add_value("library", { soil: [], wall: [], plant2d: [], greening: [], plant3d: [], source: [] })
      EnvimetInx.import_library # import lib in silent mode
    end

    def self.is_envimet_model_active?
      envi_groups = Util.get_all_active_envimet_group_guid
      envi_objects = Util.get_all_active_envimet_objects
      if envi_groups && envi_objects.empty?
        UI.messagebox("Envimet objects detected. Please, import related SKPINX to use them.")
      end
    end

    def self.set_envimet_layers
      model = Sketchup.active_model
      model.start_operation("Create Layers", true)

      result = UI.messagebox("Do you want to create envimet layers?", MB_YESNO)
      if result == IDYES
        layers = model.layers
        grid_representation = layers.add(SkpLayers::GRID)
        grid_representation.color = SkpLayers::GRID_COLOR
        SkpMaterial.create_material(SkpMaterial::GRID_MAT_NAME, SkpMaterial::GRID_PATH) if model.materials[SkpMaterial::GRID_MAT_NAME].nil?

        in_buildings = layers.add(SkpLayers::IN_BUILDING)
        in_buildings.color = SkpLayers::BUILDING_COLOR

        in_plant2d = layers.add(SkpLayers::IN_PLANT2D)
        in_plant2d.color = SkpLayers::PLANT2D_COLOR

        in_plant3d = layers.add(SkpLayers::IN_PLANT3D)
        in_plant3d.color = SkpLayers::PLANT3D_COLOR

        in_soil = layers.add(SkpLayers::IN_SOIL)
        in_soil.color = SkpLayers::SOIL_COLOR

        in_terrain = layers.add(SkpLayers::IN_TERRAIN)
        in_terrain.color = SkpLayers::TERRAIN_COLOR

        in_receptor = layers.add(SkpLayers::IN_RECEPTOR)
        in_receptor.color = SkpLayers::RECEPTOR_COLOR

        in_source = layers.add(SkpLayers::IN_SOURCE)
        in_source.color = SkpLayers::SOURCE_COLOR

        out_buildings = layers.add(SkpLayers::OUT_BUILDING)
        out_buildings.color = SkpLayers::BUILDING_COLOR
        SkpMaterial.create_material(SkpMaterial::BUILDING_MAT_NAME, SkpMaterial::BUILDING_PATH) if model.materials[SkpMaterial::BUILDING_MAT_NAME].nil?

        out_plant2d = layers.add(SkpLayers::OUT_PLANT2D)
        out_plant2d.color = SkpLayers::PLANT2D_COLOR
        SkpMaterial.create_material(SkpMaterial::PLANT2D_MAT_NAME, SkpMaterial::PLANT2D_PATH) if model.materials[SkpMaterial::PLANT2D_MAT_NAME].nil?

        out_plant3d = layers.add(SkpLayers::OUT_PLANT3D)
        out_plant3d.color = SkpLayers::PLANT3D_COLOR
        SkpMaterial.create_material(SkpMaterial::PLANT3D_MAT_NAME, SkpMaterial::PLANT3D_PATH) if model.materials[SkpMaterial::PLANT3D_MAT_NAME].nil?

        out_soil = layers.add(SkpLayers::OUT_SOIL)
        out_soil.color = SkpLayers::SOIL_COLOR
        SkpMaterial.create_material(SkpMaterial::SOIL_MAT_NAME, SkpMaterial::SOIL_PATH) if model.materials[SkpMaterial::SOIL_MAT_NAME].nil?

        out_soil = layers.add(SkpLayers::OUT_TERRAIN)
        out_soil.color = SkpLayers::TERRAIN_COLOR
        SkpMaterial.create_material(SkpMaterial::TERRAIN_MAT_NAME, SkpMaterial::TERRAIN_PATH) if model.materials[SkpMaterial::TERRAIN_MAT_NAME].nil?

        out_receptor = layers.add(SkpLayers::OUT_RECEPTOR)
        out_receptor.color = SkpLayers::RECEPTOR_COLOR
        SkpMaterial.create_material(SkpMaterial::RECEPTOR_MAT_NAME, SkpMaterial::RECEPTOR_PATH) if model.materials[SkpMaterial::RECEPTOR_MAT_NAME].nil?

        out_source = layers.add(SkpLayers::OUT_SOURCE)
        out_source.color = SkpLayers::SOURCE_COLOR
        SkpMaterial.create_material(SkpMaterial::SOURCE_MAT_NAME, SkpMaterial::SOURCE_PATH) if model.materials[SkpMaterial::SOURCE_MAT_NAME].nil?
      end

      model.commit_operation
    end

    def self.set_envimet_grid(bb_box_min, bb_box_max, type)
      model = Sketchup.active_model
      model.start_operation("Set Grid", true)

      model.select_tool(nil)

      grid = Util.get_grid_by_prompt(type)

      unless grid.nil?
        grid.set_sequence_and_extension(bb_box_min, bb_box_max)
        grid.set_x_axis
        grid.set_y_axis

        pt_min = Geom::Point3d.new(grid.other_info[:minX] - grid.dimX / 2, grid.other_info[:minY] - grid.dimY / 2, 0)
        pt_max = Geom::Point3d.new(grid.other_info[:maxX] + grid.dimX / 2, grid.other_info[:maxY] + grid.dimY / 2, 0)

        # group
        line_extension = Util.get_boundary_extension(pt_min, pt_max, grid.other_info[:height])
        base_line_extension = Util.get_base_grid(grid)
        group = Util.create_group(SkpMaterial::GRID_MAT_NAME, SkpLayers::GRID, line_extension + base_line_extension)
        Util.mark_as_envimet_group(group)

        grid.guid = group.guid
        Geometry::Grid.add_grid(grid)

        UI.messagebox("Grid calculated. Dimension #{grid.other_info[:numX] + 1},#{grid.other_info[:numY] + 1},#{grid.other_info[:numZ_cells]}.")
      else
        UI.messagebox("Calculation Failed.")
        return
      end

      model.commit_operation
    end

    def self.set_envimet_location
      if @@preparation.get_value("location").nil?

        result = Util.get_location_prompt

        if !result.nil? && result != false
          name, latitude, longitude, utc, rotation, reference_longitude = result
          location = Settings::Location.new(name, latitude, longitude, utc, rotation, reference_longitude)

          @@preparation.add_value("location", location)
        end
      else
        result = UI.messagebox("Location already exists: LAT:#{@@preparation.get_value("location").latitude}, LON:#{@@preparation.get_value("location").longitude}.\nDo you want to delete it?", MB_YESNO)
        if result == IDYES
          @@preparation.add_value("location", nil)
        else
          return
        end
      end
    end

    def self.set_envimet_building
      model = Sketchup.active_model
      model.start_operation("Set Building", true)

      unless Util.layer_exist?(SkpLayers::IN_BUILDING)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_BUILDING, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_BUILDING, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_BUILDING)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_BUILDING}' layer")
        return
      end

      wall_mat = @@preparation.get_value("library")[:wall]
      greening_mat = @@preparation.get_value("library")[:greening]
      result = Util.get_buiding_prompt(wall_mat, greening_mat) # run prompt

      if result
        grid = Geometry::Grid.get_grid.first

        name, wall_material, roof_material, green_wall, green_roof = result
        others = { wall_material: wall_material,
                   roof_material: roof_material,
                   green_wall: green_wall,
                   green_roof: green_roof }

        building = Geometry::Building.new(name, others)

        group = Util.create_group(SkpMaterial::BUILDING_MAT_NAME, SkpLayers::OUT_BUILDING, faces, groups)
        Util.mark_as_envimet_group(group)
        building.guid = group.guid # add group

        top_matrix = grid.base_matrix_2d
        bottom_matrix = grid.base_matrix_2d
        index_matrix = grid.base_matrix_2d

        intersection_top = Util.raycasting(group, grid, [SkpLayers::OUT_BUILDING, SkpLayers::IN_BUILDING], false)
        intersection_bottom = Util.raycasting(group, grid, [SkpLayers::OUT_BUILDING, SkpLayers::IN_BUILDING], true)

        building.other_info[:id_matrix] = Util.get_matrix(intersection_top, grid, index_matrix, building.index)
        building.other_info[:top_matrix] = Util.get_matrix(intersection_top, grid, top_matrix)
        building.other_info[:bottom_matrix] = Util.get_matrix(intersection_bottom, grid, bottom_matrix)

        Geometry::Building.add_buildings(building)
      end

      model.commit_operation
    end

    def self.set_envimet_2d_plant
      model = Sketchup.active_model
      model.start_operation("Set Plant2d", true)

      unless Util.layer_exist?(SkpLayers::IN_PLANT2D)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_PLANT2D, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_PLANT2D, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_PLANT2D)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_PLANT2D}' layer.")
        return
      end

      plant2d_mat = @@preparation.get_value("library")[:plant2d]
      result = Util.get_plant2d_prompt(plant2d_mat) # run prompt

      if result
        grid = Geometry::Grid.get_grid.first

        name, material = result
        others = { material: material }

        plant = Geometry::Plant2d.new(name, others)

        group = Util.create_group(SkpMaterial::PLANT2D_MAT_NAME, SkpLayers::OUT_PLANT2D, faces, groups)
        Util.mark_as_envimet_group(group)
        plant.guid = group.guid # add group

        matrix = grid.base_matrix_2d
        intersection = Util.raycasting(group, grid, [SkpLayers::OUT_PLANT2D, SkpLayers::IN_PLANT2D], false)

        plant.other_info[:matrix] = Util.get_matrix(intersection, grid, matrix, plant.other_info[:material])

        Geometry::Plant2d.add_plants(plant)
      end

      model.commit_operation
    end

    def self.set_envimet_source
      model = Sketchup.active_model
      model.start_operation("Set Source", true)

      unless Util.layer_exist?(SkpLayers::IN_SOURCE)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_SOURCE, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_SOURCE, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_SOURCE)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_SOURCE}' layer.")
        return
      end

      source_mat = @@preparation.get_value("library")[:source]
      result = Util.get_source_prompt(source_mat) # run prompt

      if result
        grid = Geometry::Grid.get_grid.first

        name, material = result
        others = { material: material }

        source = Geometry::Source.new(name, others)

        group = Util.create_group(SkpMaterial::SOURCE_MAT_NAME, SkpLayers::OUT_SOURCE, faces, groups)
        Util.mark_as_envimet_group(group)
        source.guid = group.guid # add group

        matrix = grid.base_matrix_2d
        intersection = Util.raycasting(group, grid, [SkpLayers::OUT_SOURCE, SkpLayers::IN_SOURCE], false)

        source.other_info[:matrix] = Util.get_matrix(intersection, grid, matrix, source.other_info[:material])

        Geometry::Source.add_sources(source)
      end

      model.commit_operation
    end

    def self.set_envimet_3d_plant
      model = Sketchup.active_model
      model.start_operation("Set Plant3d", true)

      unless Util.layer_exist?(SkpLayers::IN_PLANT3D)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_PLANT3D, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_PLANT3D, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_PLANT3D)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_PLANT3D}' layer.")
        return
      end

      plant3d_mat = @@preparation.get_value("library")[:plant3d]
      result = Util.get_plant3d_prompt(plant3d_mat) # run prompt

      if result
        # Get active grid
        grid = Geometry::Grid.get_grid.first

        name, material = result
        others = { material: material }

        plant = Geometry::Plant3d.new(name, others)

        group = Util.create_group(SkpMaterial::PLANT3D_MAT_NAME, SkpLayers::OUT_PLANT3D, faces, groups)
        Util.mark_as_envimet_group(group)
        plant.guid = group.guid # add group

        intersection = Util.raycasting(group, grid, [SkpLayers::OUT_PLANT3D, SkpLayers::IN_PLANT3D], false)

        pixels = Util.get_pixels_from_intersection(intersection, grid)

        plant.other_info[:pixels] = pixels

        Geometry::Plant3d.add_plants(plant)
      end

      model.commit_operation
    end

    def self.set_envimet_soil
      model = Sketchup.active_model
      model.start_operation("Set Soil", true)

      unless Util.layer_exist?(SkpLayers::IN_SOIL)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_SOIL, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_SOIL, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_SOIL)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_SOIL}' layer.")
        return
      end

      soil_mat = @@preparation.get_value("library")[:soil]
      result = Util.get_soil_prompt(soil_mat) # run prompt

      if result
        grid = Geometry::Grid.get_grid.first

        name, material = result
        others = { material: material }

        soil = Geometry::Soil.new(name, others)

        group = Util.create_group(SkpMaterial::SOIL_MAT_NAME, SkpLayers::OUT_SOIL, faces, groups)
        Util.mark_as_envimet_group(group)
        soil.guid = group.guid # add group

        matrix = grid.base_matrix_2d
        intersection = Util.raycasting(group, grid, [SkpLayers::OUT_SOIL, SkpLayers::IN_SOIL], false)

        soil.other_info[:matrix] = Util.get_matrix(intersection, grid, matrix, soil.other_info[:material])

        Geometry::Soil.add_soils(soil)
      end

      model.commit_operation
    end

    def self.set_envimet_terrain
      model = Sketchup.active_model
      model.start_operation("Set Terrain", true)

      unless Util.layer_exist?(SkpLayers::IN_TERRAIN)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_TERRAIN, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_TERRAIN, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_TERRAIN)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_TERRAIN}' layer.")
        return
      end

      result = Util.get_terrain_prompt # run prompt

      if result
        grid = Geometry::Grid.get_grid.first

        name = result.first
        others = {}

        terrain = Geometry::Terrain.new(name)

        group = Util.create_group(SkpMaterial::TERRAIN_MAT_NAME, SkpLayers::OUT_TERRAIN, faces, groups)
        Util.mark_as_envimet_group(group)
        terrain.guid = group.guid # add group

        matrix = grid.base_matrix_2d
        intersection = Util.raycasting(group, grid, [SkpLayers::OUT_TERRAIN, SkpLayers::IN_TERRAIN], false)

        terrain.other_info[:matrix] = Util.get_matrix(intersection, grid, matrix)

        Geometry::Terrain.add_terrain(terrain)
      end

      model.commit_operation
    end

    def self.set_envimet_receptor
      model = Sketchup.active_model
      model.start_operation("Set Receptor", true)

      unless Util.layer_exist?(SkpLayers::IN_RECEPTOR)
        Util.layer_warning
        return
      end

      unless Util.grid_exist?
        return
      end

      faces = Util.select_element_by_layer(SkpLayers::IN_RECEPTOR, Sketchup::Face)
      groups = Util.select_element_by_layer(SkpLayers::IN_RECEPTOR, Sketchup::Group)

      groups.each do |entity|
        Util.change_layer_of_selection_to_target_layer(entity, SkpLayers::IN_RECEPTOR)
      end

      if faces.empty? && groups.empty?
        UI.messagebox("Please, select Faces or Groups from '#{SkpLayers::IN_RECEPTOR}' layer.")
        return
      end

      result = Util.get_receptor_prompt

      if result
        grid = Geometry::Grid.get_grid.first

        name = result.first

        receptor_group = Geometry::Receptor.new(name)

        group = Util.create_group(SkpMaterial::RECEPTOR_MAT_NAME, SkpLayers::OUT_RECEPTOR, faces, groups)
        Util.mark_as_envimet_group(group)
        receptor_group.guid = group.guid # add group

        intersection = Util.raycasting(group, grid, [SkpLayers::OUT_RECEPTOR, SkpLayers::IN_RECEPTOR], false)

        pixels = Util.get_pixels_from_intersection(intersection, grid, false)

        receptor_group.other_info[:pixels] = pixels

        Geometry::Receptor.add_receptors(receptor_group)
      end

      model.commit_operation
    end

    def self.get_envimet_entity_info
      model = Sketchup.active_model
      selection = model.selection
      if selection.to_a.empty?
        UI.messagebox("Please, select an envimet object and then press 'Info Envimet Object' button.")
        return
      end
      group = selection.grep(Sketchup::Group).first

      attribute = group.get_attribute("type", "ID", nil) if group # only Envimet entities
      existing_guid = Util::MAPPING_LAYER_TYPE[group.layer.name].get_existing_guid if attribute && group

      if !existing_guid.nil? && existing_guid.include?(group.guid)
        object = Util::MAPPING_LAYER_TYPE[group.layer.name].get_by_group_guid(group.guid)
        values = object.first.to_s
        MessageBox.show_messagebox("Envimet Object Information", values)
      end
    end

    def self.delete_envimet_object
      model = Sketchup.active_model
      model.start_operation("Delete Object", true)
      selection = model.selection
      if selection.to_a.empty?
        UI.messagebox("Please, select an envimet object and then press 'Delete Envimet Object' button.")
        return
      end
      result = UI.messagebox("Undo operation of this command does not restore envimet object data of selected objects. Do you want to procede anyway?", MB_YESNO)

      names = selection.grep(Sketchup::Group).map { |grp| grp.layer.name }

      if result == IDYES && !names.include?(SkpLayers::GRID)
        groups = selection.grep(Sketchup::Group)
        groups.each { |group| Util.delete_single_object(group) }
        UI.messagebox("Envimet Object deleted!")
      elsif result == IDYES && names.include?(SkpLayers::GRID)
        result = UI.messagebox("All envimet object depend on envimet grid. Do you want to delete all objects?", MB_YESNO)
        if result == IDYES
          Util.delete_all_object
          UI.messagebox("Envimet Objects deleted!")
        end
      end
      model.commit_operation
    end

    def self.export_envimet_objects
      objects = Util.get_all_active_envimet_objects

      objects.select!(&(Util::CLEAN_GROUP))

      full_path = UI.savepanel(title = "Save Envimet SKPINX", filename = "#{Util.get_default_file_name}.skpinx")
      Serializer.write_file(full_path, objects + [@@preparation.get_value("location")]) unless full_path.nil?
      UI.messagebox("SKPINX exported.") unless full_path.nil?
    end

    def self.import_envimet_objects
      chosen_image = UI.openpanel("Open Envimet SKPINX", "./", "SKPINX|*.skpinx;||")

      objects = Serializer.read_file(chosen_image) unless chosen_image.nil?

      # unwrap
      objects.each do |obj|
        Geometry::Grid.add_grid(obj)
        Geometry::Building.add_buildings(obj)
        Geometry::Plant2d.add_plants(obj)
        Geometry::Plant3d.add_plants(obj)
        Geometry::Soil.add_soils(obj)
        Geometry::Terrain.add_terrain(obj)
        Geometry::Receptor.add_receptors(obj)
        Geometry::Source.add_sources(obj)
        if obj.is_a?(Settings::Location)
          @@preparation.add_value("location", obj)
        end
      end if objects

      Geometry::Building.set_index(objects)
      Geometry::Plant2d.set_index(objects)
      Geometry::Plant3d.set_index(objects)
      Geometry::Soil.set_index(objects)
      Geometry::Terrain.set_index(objects)
      Geometry::Source.set_index(objects)

      UI.messagebox("SKPINX imported.") unless chosen_image.nil?
    end

    def self.install_envimet_standard_db
      ref_db_path = IO::Library::STANDARD_ENVIMET_PATH

      # installation
      database_edb = nil
      if Util.is_standard_library_empty?
        envimet_folder = UI.select_directory(title: "Select Envimet Folder (E.g. C:\\ENVImet444)")
        unless envimet_folder.nil?
          syslib = File.join(envimet_folder, IO::Library::SYS_LIBRARY)
          userlib = File.join(envimet_folder, IO::Library::USER_LIBRARY)

          database_edb = syslib
          if File.exist?(userlib)
            result = UI.messagebox("Do you want to use system database?\nIf you select 'No' user library is used.", MB_YESNO)
            database_edb = result == IDYES ? syslib : userlib
          end

          if database_edb && File.exist?(database_edb)
            unless ["database", "userdatabase"].include?(File.basename(database_edb, ".edb"))
              UI.messagebox("Database file not found.\nPlease, check if there are *.edb files in 'sys.basedata' or 'sys.userdata' of ENVI-met folder.")
              return
            end

            File.open(ref_db_path, "w") { |file| file.write(database_edb) }
          end
        end
      else
        result = UI.messagebox("Library already installed. Do you want to delete it?", MB_YESNO)
        if result == IDYES
          File.open(ref_db_path, "w") { |file| file.write("") }
          @@preparation.add_value("library", { soil: [], wall: [], plant2d: [], greening: [] })
          UI.messagebox("Library deleted.")
          return
        else
          return
        end
      end

      self.import_library(false)
    end

    def self.import_library(silent_mode = true)
      unless Util.is_standard_library_empty?
        path = IO::Library.get_library_path_from_plugin(IO::Library::STANDARD_ENVIMET_PATH)
        library = IO::Library.get_envimet_library(path)
        unless library
          UI.messagebox("Unable to parse #{File.basename(IO::Library::STANDARD_ENVIMET_PATH)}.")
          return
        end
        @@preparation.add_value("library", library)
        UI.messagebox("Library imported, you will see material IDs in envimet prompts.\nIf you want to see material details open 'Database Manager' of ENVI-met Headquarter.") unless silent_mode
      end
    end

    def self.write_inx_file
      inx = IO::Inx.new
      doc = inx.create_xml(@@preparation)

      if doc.nil?
        UI.messagebox("Please, create both Envimet Location and Grid first.")
        return
      end

      full_path = UI.savepanel(title = "Save Envimet INX", filename = "#{Util.get_default_file_name}.INX")
      inx.write_xml(doc, full_path) unless full_path.nil?
    end
  end # end EnvimetInx
end # end Envimet
