module Envimet::EnvimetInx

  def self.create_envimet_layers

    model = Sketchup.active_model
    model.start_operation("Create Layers", true)

    result = UI.messagebox("Click Ok to create ENVI_MET layers.", MB_OK)
    if result == IDOK

      layers = model.layers
      buildings = layers.add("buildings")
      buildings.color = Sketchup::Color.new(232, 245, 233)

      layers = model.layers
      context = layers.add("context")
      context.color = Sketchup::Color.new(232, 245, 233)

      plant2d = layers.add("plant2d")
      plant2d.color = Sketchup::Color.new(129, 199, 132)

      soil = layers.add("soil")
      soil.color = Sketchup::Color.new(27, 94, 32)

      grid_representation = layers.add("grid_representation")
      grid_representation.color = Sketchup::Color.new(0, 200, 83)

    end

    model.commit_operation

  end


  def self.set_envimet_location

    prompts = ["Location Name"]
    default = ["My Location"]
    results = UI.inputbox(prompts, default, "Set Location")

    geolocation_info = Sketchup.active_model.attribute_dictionaries["GeoReference"]
    latitude, longitude = geolocation_info["Latitude"], geolocation_info["Longitude"]

    location = Location.new(results[0], latitude, longitude)

    @@preparation.add_value("location", location)

  end


  def self.set_envimet_grid

    model = Sketchup.active_model
    model.start_operation("Set Grid", true)

    model.select_tool(nil)

    prompts = ["Dim X", "Dim Y", "Dim Z", "Start Telescope Height", "Telescope", "AddictionalCells Left", "AddictionalCells Right", "AddictionalCells Up", "AddictionalCells Down"]
    defaults = [3.0, 3.0, 3.0, 5.0, 0.0, 2, 2, 2, 2]
    results = UI.inputbox(prompts, defaults, "Create Grid")

    if results != false

      dimX, dimY, dimZ, start_telescope, telescope, addLeft, addRight, addUp, addDown = results
      others = { telescope:telescope, startTelescopeHeigth:start_telescope, addictional_grid_left:addLeft, addictional_grid_right:addRight, addictional_grid_up:addUp, addictional_grid_down:addDown }

      grid = Grid.new(dimX, dimY, dimZ, others)

      bb_box = self.get_bbox_by_layer(["buildings", "context"])
      grid.gZmethod(bb_box.min, bb_box.max)
      grid.grid_preview_3d

      if grid.grid_preview_3d.empty?
        UI.messagebox("Calculation Failed... Grid is based on buildings or context. Please, create a solid building using the right layer.")
        return
      end

      bb_box.add(grid.grid_3d_points)
      self.create_boundary_box(bb_box.min, bb_box.max)

      @@preparation.add_value("grid", grid)

    end

    model.commit_operation

  end

  def self.set_envimet_building

    model = Sketchup.active_model
    model.start_operation("Set Building", true)

    grid = @@preparation.get_value("grid")

    model.select_tool(nil)

    if grid.nil?
      UI.messagebox("Please, create grid first.")
    else
      building = Building.new(1)
      context = Building.new(2)

      val = grid.repartition_z.last.m
      

      materials = self.set_building_materials("Building Materials")
      building.wall_material, building.roof_material = materials

      voxels = self.voxels_3d(grid, "buildings")
      building.create_voxel_matrix(voxels, grid)

      # top
      grid.grid_preview_xy(val)
      top_voxel_points_buildings, top_points_buildings = self.voxels_2d(grid, "buildings", false)
      # bottom
      grid.grid_preview_xy(-val)
      bottom_voxel_points_buildings, bottom_points_buildings = self.voxels_2d(grid, "buildings")

      self.show_layers
      UI.messagebox("Building calculated!")

      materials = self.set_building_materials("Context Materials")
      context.wall_material, context.roof_material = materials

      voxels = self.voxels_3d(grid, "context")
      context.create_voxel_matrix(voxels, grid)

      # top
      grid.grid_preview_xy(val)
      top_voxel_points_context, top_points_context = self.voxels_2d(grid, "context", false)
      # bottom
      grid.grid_preview_xy(-val)
      bottom_voxel_points_context, bottom_points_context = self.voxels_2d(grid, "context")

      UI.messagebox("Context calculated!")

      matrix = Building.merge_matrix(building.matrix, context.matrix, MERGE)
      db_matrix = Building.set_materials(matrix, [building.wall_material, context.wall_material], [building.roof_material, context.roof_material])

      preparation_matrix = Building.merge_matrix(building.matrix, context.matrix, MAX)
      id_matrix = Grid.get_envimet_matrix(Grid.merge_2d(preparation_matrix))

      bld_2d_top = Object2d.new("000000")
      bld_2d_down = Object2d.new("000000")
      bld_2d_top.create_voxel_2d_matrix(top_voxel_points_buildings.concat(top_voxel_points_context), grid, top_points_buildings.concat(top_points_context), 0)
      bld_2d_down.create_voxel_2d_matrix(bottom_voxel_points_buildings.concat(bottom_voxel_points_context), grid, bottom_points_buildings.concat(bottom_points_context), 0)

      top_matrix = Grid.get_envimet_matrix(bld_2d_top.matrix)
      bottom_matrix = Grid.get_envimet_matrix(bld_2d_down.matrix)

      @@preparation.add_value("db_matrix", db_matrix)
      @@preparation.add_value("id_matrix", id_matrix)
      @@preparation.add_value("building_flag_and_nr", building.building_flag_and_nr + context.building_flag_and_nr)
      @@preparation.add_value("top_matrix", top_matrix)
      @@preparation.add_value("bottom_matrix", bottom_matrix)

    end

    self.show_layers
    model.commit_operation

  end


  def self.set_building_materials(text)

    prompts = ["Wall Material", "Roof Material"]
    defaults = ["000000", "000000"]
    results = UI.inputbox(prompts, defaults, text)
    results = defaults if results.is_a?(FalseClass)

    results

  end


  def self.set_2dplant_material(text)

    prompts = ["2d Plant Material"]
    defaults = ["0000XX"]
    results = UI.inputbox(prompts, defaults, text)
    
    results

  end


  def self.set_plant2d

    model = Sketchup.active_model
    model.start_operation("Set Plant2d", true)

    grid = @@preparation.get_value("grid")

    model.select_tool(nil)

    if grid.nil?
      UI.messagebox("Please, create grid first.")
      return
    end

    grid.grid_preview_xy(-grid.repartition_z.last.m)
    voxel_points, intersection_points = self.voxels_2d(grid, "plant2d" )
    self.show_layers

    material = self.set_2dplant_material("2D Plant Material")
    plant2d = Object2d.new(material)

    plant2d.create_voxel_2d_matrix(voxel_points, grid)

    plant_2d = Grid.get_envimet_matrix(plant2d.matrix)
    @@preparation.add_value("plant_2d", plant_2d)

    UI.messagebox("2D Plants calculated!")

    model.commit_operation

  end


  def self.write_file

    inx = EnvimetXml.new
    doc = inx.create_xml(@@preparation)

    if doc.nil?
      UI.messagebox("Create location, grid, building, trees first.")
      return
    end

    full_path = UI.savepanel(title="Save Envimet INX", filename="EnvimetSkp.INX")
    inx.write_xml(doc, full_path) unless full_path.nil?

  end

end
