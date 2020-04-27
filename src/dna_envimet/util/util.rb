module Envimet
  module EnvimetInx
    Pixel = Struct.new(:i, :j)

    module Util
      MAPPING_LAYER_TYPE = { SkpLayers::GRID => Geometry::Grid,
                            SkpLayers::OUT_BUILDING => Geometry::Building,
                            SkpLayers::OUT_PLANT2D => Geometry::Plant2d,
                            SkpLayers::OUT_PLANT3D => Geometry::Plant3d,
                            SkpLayers::OUT_SOIL => Geometry::Soil,
                            SkpLayers::OUT_TERRAIN => Geometry::Terrain,
                            SkpLayers::OUT_RECEPTOR => Geometry::Receptor,
                            SkpLayers::OUT_SOURCE => Geometry::Source }

      CLEAN_GROUP = Proc.new { |obj| self.get_all_active_envimet_group_guid.include?(obj.guid) }

      def self.get_boundary_extension(pt_min, pt_max, height)
        model = Sketchup.active_model
        entities = model.active_entities
        model.active_layer = SkpLayers::GRID

        pt1 = pt_min
        pt8 = Geom::Point3d.new(pt_max.x, pt_max.y, height)

        pt2 = Geom::Point3d.new(pt8.x, pt1.y, pt1.z)
        pt3 = Geom::Point3d.new(pt1.x, pt1.y, pt8.z)
        pt4 = Geom::Point3d.new(pt8.x, pt1.y, pt8.z)

        pt5 = Geom::Point3d.new(pt1.x, pt8.y, pt1.z)
        pt6 = Geom::Point3d.new(pt8.x, pt8.y, pt1.z)
        pt7 = Geom::Point3d.new(pt1.x, pt8.y, pt8.z)

        poits = [pt1, pt2, pt3, pt4, pt5, pt6, pt7, pt8]

        combination = poits.combination(2).to_a

        lines = []
        combination.each { |pts| lines << entities.add_cline(pts[0], pts[1]) if self.point_comparison_validation(pts[0], pts[1]) }

        lines
      end

      def self.get_base_grid(grid)
        dist_x = grid.dimX / 2
        dist_y = grid.dimY / 2

        sequence_y = grid.other_info[:y_axis].dup.map { |n| n + dist_y }
        sequence_x = grid.other_info[:x_axis].dup.map { |n| n + dist_x }

        lines = []
        entities = Sketchup.active_model.entities
        sequence_y.each { |dist| lines << entities.add_cline(Geom::Point3d.new(grid.other_info[:minX] - dist_x, dist, 0), Geom::Point3d.new(grid.other_info[:x_axis].last + dist_x, dist, 0)) }
        sequence_x.each { |dist| lines << entities.add_cline(Geom::Point3d.new(dist, grid.other_info[:minY] - dist_y, 0), Geom::Point3d.new(dist, grid.other_info[:y_axis].last + dist_y, 0)) }
        lines
      end

      def self.point_comparison_validation(pt1, pt2)
        (pt1.x == pt2.x && pt1.y == pt2.y) || (pt1.x == pt2.x && pt1.z == pt2.z) || (pt1.y == pt2.y && pt1.z == pt2.z)
      end

      def self.select_element_by_layer(layer, skp_type)
        model = Sketchup.active_model
        selection = model.selection
        elements = selection.grep(skp_type)
        selected_elements = elements.select { |element| element.layer.name == layer }
        selected_elements
      end

      def self.grid_exist?
        if Geometry::Grid.get_grid.empty?
          UI.messagebox("Please, create Envimet Grid first.")
          return false
        end
        true
      end

      def self.layer_warning
        UI.messagebox("Please, create Envimet Layers first.")
      end

      def self.mark_as_envimet_group(group)
        group.set_attribute("type", "ID", "ENVI_MET")
      end

      def self.delete_all_object
        active_group = Sketchup.active_model.entities.grep(Sketchup::Group)
        active_group.each { |group| self.delete_single_object(group) }
      end

      def self.delete_single_object(group)
        attribute = group.get_attribute("type", "ID", nil) if group # only Envimet entities
        existing_guid = Util::MAPPING_LAYER_TYPE[group.layer.name].get_existing_guid if attribute && group

        if !existing_guid.nil? && existing_guid.include?(group.guid)
          Util::MAPPING_LAYER_TYPE[group.layer.name].delete_by_group_guid(group.guid)
          initial_layer = group.layer.name
          group.material = nil
          group.layer = "Layer0"
          group.locked = false
          group.delete_attribute("type")
          group.explode unless initial_layer == SkpLayers::GRID
        end
      end

      def self.get_all_active_envimet_objects
        grid = Geometry::Grid.get_grid ? Geometry::Grid.get_grid : []
        buildings = Geometry::Building.get_buildings ? Geometry::Building.get_buildings : []
        plants = Geometry::Plant2d.get_plants ? Geometry::Plant2d.get_plants : []
        plants3d = Geometry::Plant3d.get_plants ? Geometry::Plant3d.get_plants : []
        soils = Geometry::Soil.get_soils ? Geometry::Soil.get_soils : []
        terrain = Geometry::Terrain.get_terrain ? Geometry::Terrain.get_terrain : []
        receptor = Geometry::Receptor.get_receptors ? Geometry::Receptor.get_receptors : []
        sources = Geometry::Source.get_sources ? Geometry::Source.get_sources : []

        objects = grid + buildings + plants + soils + terrain + plants3d + receptor + sources
        objects
      end

      def self.get_all_active_envimet_group_guid
        groups = Sketchup.active_model.entities.grep(Sketchup::Group).select { |group| group.get_attribute("type", "ID", nil) }
        groups.map { |group| group.guid } if groups
      end

      def self.layer_exist?(layer)
        layer_names = Sketchup.active_model.layers.to_a.map { |l| l.name }
        layer_names.include?(layer)
      end

      def self.get_buiding_prompt(wall, greening)
        prompts = ["Name", "Wall Material", "Roof Material", "Green Wall Material", "Green Roof Material"]
        defaults = [" ", Geometry::Building::DEFAULT_WALL_MATERIAL, Geometry::Building::DEFAULT_ROOF_MATERIAL, " ", " "]
        list = ["", wall.join("|"), wall.join("|"), greening.join("|"), greening.join("|")]
        result = UI.inputbox(prompts, defaults, list, "Create Envimet Building", MB_OK)

        result
      end

      def self.get_location_prompt(geolocation)
        latitude, longitude, locationsource, north = geolocation["Latitude"], geolocation["Longitude"], geolocation["LocationSource"], geolocation["GeoReferenceNorthAngle"]

        prompts = ["Location Name", "Latitude", "Longitude", "Time Zone", "GeoReference North Angle"]
        default = [locationsource, latitude, longitude, "UTC-7", north]
        list = ["", "", "", Settings::Location::UTC, ""]
        result = UI.inputbox(prompts, default, list, "Set Location")

        result
      end

      def self.get_plant2d_prompt(plant2d)
        prompts = ["Name", "Material"]
        defaults = [" ", Geometry::Plant2d::DEFAULT_PLANT2D_MATERIAL]
        list = ["", plant2d.join("|")]
        result = UI.inputbox(prompts, defaults, list, "Create Envimet Plant2d", MB_OK)

        result
      end

      def self.get_source_prompt(source)
        prompts = ["Name", "Material"]
        defaults = [" ", Geometry::Source::DEFAULT_SOURCE_MATERIAL]
        list = ["", source.join("|")]
        result = UI.inputbox(prompts, defaults, list, "Create Envimet Source", MB_OK)

        result
      end

      def self.get_receptor_prompt
        prompts = ["Name"]
        defaults = ["Rec"]
        result = UI.inputbox(prompts, defaults, "Create Envimet Receptor", MB_OK)

        result
      end

      def self.get_plant3d_prompt(plant3d)
        prompts = ["Name", "Material"]
        defaults = [Geometry::Plant3d::DEFAULT_NAME, Geometry::Plant3d::DEFAULT_PLANT3D_MATERIAL]
        list = ["", plant3d.join("|")]
        result = UI.inputbox(prompts, defaults, list, "Create Envimet Plant3d", MB_OK)

        result
      end

      def self.get_soil_prompt(soil)
        prompts = ["Name", "Material"]
        defaults = [" ", Geometry::Soil::DEFAULT_SOIL_MATERIAL]
        list = ["", soil.join("|")]
        result = UI.inputbox(prompts, defaults, list, "Create Envimet Soil", MB_OK)

        result
      end

      def self.get_terrain_prompt
        prompts = ["Name"]
        defaults = [" "]
        result = UI.inputbox(prompts, defaults, "Create Envimet Terrain", MB_OK)

        result
      end

      def self.show_layers
        Sketchup.active_model.layers.each { |l| l.visible = true }
      end

      def self.hide_layers_except(input_layers)
        Sketchup.active_model.layers.each { |l| l.visible = false unless input_layers.include?(l.name) }
      end

      def self.is_standard_library_empty?
        File.new(IO::Library::STANDARD_ENVIMET_PATH).size == 0
      end

      def self.create_group(material_name, layer, *objects)
        model = Sketchup.active_model
        model.active_layer = layer
        entities = model.active_entities
        group = entities.add_group(*objects)
        group.make_unique
        group.material = material_name
        group.locked = true
        model.active_layer = "Layer0"

        group
      end

      def self.get_group_global_min_max(group)
        boundingbox = group.local_bounds
        min_pt = boundingbox.min.transform(group.transformation) # to global
        max_pt = boundingbox.max.transform(group.transformation) # to global
        return min_pt, max_pt
      end

      def self.get_default_file_name
        current_path = Sketchup.active_model.path
        file_name = current_path.empty? ? "Envimet" : File.basename(current_path, ".*") # get skp file name
        file_name
      end

      def self.filter_array_by_limit(values, lower_limit, upper_limit)
        arr = values.dup
        arr.keep_if { |num| num >= lower_limit && num <= upper_limit }
      end

      def self.get_merged_matrix(objects, type, default)
        objects.sort_by! { |obj| obj.index }

        matrix = objects.map { |obj| obj.other_info[type] }

        merged_matrix = Geometry::Grid.merge_2d(matrix, default)
        Geometry::Grid.get_envimet_matrix(merged_matrix)
      end

      def self.get_grid_by_prompt(type)
        if type == "1"
          prompts = ["Num Z cells", "Dim X(m)", "Dim Y(m)", "Dim Z(m)", "AddictionalCells Left", "AddictionalCells Right", "AddictionalCells Up", "AddictionalCells Down"]
          defaults = [15, 3.0, 3.0, 3.0, 0, 0, 0, 0]
          results = UI.inputbox(prompts, defaults, "Create Equidistant Grid")

          if results
            numZ_cells, dimX, dimY, dimZ, addLeft, addRight, addUp, addDown = results
            others = { grid_type: Geometry::Grid::GRID_TYPE[type],
                       numZ_cells: numZ_cells,
                       addictional_grid_left: addLeft,
                       addictional_grid_right: addRight,
                       addictional_grid_up: addUp,
                       addictional_grid_down: addDown }
            return Geometry::Grid.new(dimX, dimY, dimZ, others)
          end
        elsif type == "2"
          prompts = ["Num Z cells", "Dim X(m)", "Dim Y(m)", "Dim Z(m)", "Start Telescope Height", "Telescope", "AddictionalCells Left", "AddictionalCells Right", "AddictionalCells Up", "AddictionalCells Down"]
          defaults = [15, 3.0, 3.0, 3.0, 6.0, 8.0, 0, 0, 0, 0]
          results = UI.inputbox(prompts, defaults, "Create Telescope Grid")

          if results
            numZ_cells, dimX, dimY, dimZ, start_telescope, telescope, addLeft, addRight, addUp, addDown = results
            others = { grid_type: Geometry::Grid::GRID_TYPE[type],
                       numZ_cells: numZ_cells,
                       telescope: telescope,
                       start_telescope_heigth: start_telescope,
                       addictional_grid_left: addLeft,
                       addictional_grid_right: addRight,
                       addictional_grid_up: addUp,
                       addictional_grid_down: addDown }
            return Geometry::Grid.new(dimX, dimY, dimZ, others)
          end
        else
          prompts = ["Num Z cells", "Dim X(m)", "Dim Y(m)", "Dim Z(m)", "Start Telescope Height", "Telescope", "AddictionalCells Left", "AddictionalCells Right", "AddictionalCells Up", "AddictionalCells Down"]
          defaults = [15, 3.0, 3.0, 3.0, 6.0, 8.0, 0, 0, 0, 0]
          results = UI.inputbox(prompts, defaults, "Create Combined Grid")

          if results
            numZ_cells, dimX, dimY, dimZ, start_telescope, telescope, addLeft, addRight, addUp, addDown = results
            others = { grid_type: Geometry::Grid::GRID_TYPE[type],
                       numZ_cells: numZ_cells,
                       telescope: telescope,
                       start_telescope_heigth: start_telescope,
                       addictional_grid_left: addLeft,
                       addictional_grid_right: addRight,
                       addictional_grid_up: addUp,
                       addictional_grid_down: addDown }
            return Geometry::Grid.new(dimX, dimY, dimZ, others)
          end
        end
      end

      def self.get_matrix(intersection, grid, matrix, text = nil)
        rounded_x_axis = grid.other_info[:x_axis].map { |num| num.round(3) }
        rounded_y_axis = grid.other_info[:y_axis].map { |num| num.round(3) }

        intersection.each do |pt|
          index_x = rounded_x_axis.index(pt.x)
          index_y = rounded_y_axis.index(pt.y)
          matrix[index_y][index_x] = text.nil? ? pt.z.to_m.round(0) : text
        end
        matrix
      end

      def self.get_pixels_from_intersection(intersection, grid, shift_one = true)
        rounded_x_axis = grid.other_info[:x_axis].map { |num| num.round(3) }
        rounded_y_axis = grid.other_info[:y_axis].map { |num| num.round(3) }

        pixels = []

        addictional_cell = shift_one ? 1 : 0

        intersection.each do |pt|
          index_x = rounded_x_axis.index(pt.x) + addictional_cell
          index_y = rounded_y_axis.index(pt.y) + addictional_cell

          pixels << Pixel.new(index_x, index_y)
        end
        pixels
      end

      def self.raycasting(group, grid, layers, from_bottom = true)
        model = Sketchup.active_model

        min, max = Util.get_group_global_min_max(group)
        ray_x_position = Util.filter_array_by_limit(grid.other_info[:x_axis], min.x, max.x)
        ray_y_position = Util.filter_array_by_limit(grid.other_info[:y_axis], min.y, max.y)

        model.active_layer = "Layer0"
        Util.hide_layers_except(layers)

        z = from_bottom ? -grid.other_info[:height] : grid.other_info[:height]
        unit = from_bottom ? 1 : -1

        intersection = []
        ray_y_position.each do |y|
          ray_x_position.each do |x|
            ray = [Geom::Point3d.new(x, y, z), Geom::Vector3d.new(0, 0, unit)]
            items = model.raytest(ray, true)
            unless items.nil?
              intersection << items.first if items.last[0].is_a?(Sketchup::Group) && items.last[0].guid == group.guid
            end
          end
        end
        Util.show_layers

        intersection
      end
    end # end Util
  end # end EnvimetInx
end # end Envimet
