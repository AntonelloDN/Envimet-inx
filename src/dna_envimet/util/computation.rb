module Envimet
  module EnvimetInx
    def self.set_geometries
      grid = []
      soil = []
      plant2d = []
      plant3d = []
      terrain = []
      building = []
      receptor = []
      source = []

      objects = Util.get_all_active_envimet_objects
      objects.select!(&(Util::CLEAN_GROUP))
      objects.each do |obj|
        grid << obj if obj.is_a?(Geometry::Grid)
        soil << obj if obj.is_a?(Geometry::Soil)
        plant2d << obj if obj.is_a?(Geometry::Plant2d)
        plant3d << obj if obj.is_a?(Geometry::Plant3d)
        terrain << obj if obj.is_a?(Geometry::Terrain)
        building << obj if obj.is_a?(Geometry::Building)
        receptor << obj if obj.is_a?(Geometry::Receptor)
        source << obj if obj.is_a?(Geometry::Source)
      end

      if grid == []
        return
      end

      @@preparation.add_value("grid", grid)
      @@preparation.add_value("soil", soil)
      @@preparation.add_value("plant2d", plant2d)
      @@preparation.add_value("plant3d", plant3d)
      @@preparation.add_value("terrain", terrain)
      @@preparation.add_value("building", building)
      @@preparation.add_value("receptor", receptor)
      @@preparation.add_value("source", source)

      @@preparation.add_value("zero_matrix", get_default_matrix(@@preparation.get_value("grid").first, 0))

      # 2d matrix
      set_building_matrix
      set_soil_matrix
      set_plant2d_matrix
      set_terrain_matrix
      set_source_matrix
    end

    def self.set_building_matrix
      building = @@preparation.get_value("building")
      top_matrix = Util.get_merged_matrix(building, :top_matrix, 0)
      bottom_matrix = Util.get_merged_matrix(building, :bottom_matrix, 0)
      id_matrix = Util.get_merged_matrix(building, :id_matrix, 0)

      default_matrix = get_default_matrix(@@preparation.get_value("grid").first)
      top_matrix = default_matrix if top_matrix == IO::Inx::NEWLINE
      bottom_matrix = default_matrix if bottom_matrix == IO::Inx::NEWLINE
      id_matrix = default_matrix if id_matrix == IO::Inx::NEWLINE

      @@preparation.add_value("top_matrix", top_matrix)
      @@preparation.add_value("bottom_matrix", bottom_matrix)
      @@preparation.add_value("id_matrix", id_matrix)
    end

    def self.set_soil_matrix
      soil = @@preparation.get_value("soil")
      soil_matrix = Util.get_merged_matrix(soil, :matrix, Geometry::Soil::BASE_SOIL_MATERIAL)

      default_matrix = get_default_matrix(@@preparation.get_value("grid").first, Geometry::Soil::BASE_SOIL_MATERIAL)
      soil_matrix = default_matrix if soil_matrix == IO::Inx::NEWLINE

      @@preparation.add_value("soil_matrix", soil_matrix)
    end

    def self.set_plant2d_matrix
      plant = @@preparation.get_value("plant2d")
      plant2d_matrix = Util.get_merged_matrix(plant, :matrix, "")

      @@preparation.add_value("plant2d_matrix", plant2d_matrix)
    end

    def self.set_source_matrix
      source = @@preparation.get_value("source")
      source_matrix = Util.get_merged_matrix(source, :matrix, "")

      @@preparation.add_value("source_matrix", source_matrix)
    end

    def self.set_terrain_matrix
      terrain = @@preparation.get_value("terrain")
      terrain_matrix = Util.get_merged_matrix(terrain, :matrix, 0)

      default_matrix = get_default_matrix(@@preparation.get_value("grid").first)
      terrain_matrix = default_matrix if terrain_matrix == IO::Inx::NEWLINE

      @@preparation.add_value("terrain_matrix", terrain_matrix)
    end

    def self.get_default_matrix(grid, default = 0)
      matrix = grid.base_matrix_2d(default)
      Geometry::Grid.get_envimet_matrix(matrix)
    end
  end # end EnvimetInx
end # end Envimet
