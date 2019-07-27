module Envimet::EnvimetInx

  class Object2d

    attr_accessor :geometry, :material, :matrix
    attr_reader :name

    def initialize(material, name="Plant_2d")

      @material = material
      @name = name

      @matrix = []
    end

    def create_voxel_2d_matrix(voxel_points, grid, intersection_points = [], empty_val = "")

      self.matrix = grid.base_matrix_2d(empty_val)

      voxel_points.zip(intersection_points).each do |pt, int_pt|
        valX = ((pt.x - grid.other_info[:minX]) / grid.dimX).round(0)
        valY = ((pt.y - grid.other_info[:minY]) / grid.dimY).round(0)

        valX = valX.to_i
        valY = valY.to_i

        self.matrix[valY][valX] = intersection_points.empty? ? self.material : int_pt.z.to_m.round(0)

      end

    end

  end

end
