module Envimet::EnvimetInx


  MERGE = Proc.new do |element1, element2|
    val = element1 + element2
    if val > 2
      val = 0
    end
    val
  end

  MAX = Proc.new do |element1, element2|
    val = [element1, element2].max
    val.round(0)
  end

  class Grid

    attr_reader :dimX, :dimY, :dimZ, :repartition_z
    attr_accessor :other_info, :grid_3d_points, :grid_2d_points

    def initialize(dimX=3.0, dimY=3.0, dimZ=3.0, others = {})

      values = {
        addictional_grid_left:2,
        addictional_grid_right:2,
        addictional_grid_up:2,
        addictional_grid_down:2,
        telescope:0.0 ,
        startTelescopeHeigth:5.0
      }

      values.merge!(others)

      @dimX = dimX.m
      @dimY = dimY.m
      @dimZ = dimZ.m

      @other_info = values
      @repartition_z = nil
      @grid_3d_points = []
      @grid_2d_points = []

    end

    def get_dimensions
      "Dimensions: #{dimX}, #{dimY}, #{dimZ}, #{other_info[:addictional_grid_right]}"
    end

    def delete_point(pt)
      @grid_3d_points.delete(pt)
    end

    def gZmethod(bb_min, bb_max)

      distLeft = other_info[:addictional_grid_left] * dimX
      distRight = other_info[:addictional_grid_right] * dimX
      distUp = other_info[:addictional_grid_up] * dimY
      distDown = other_info[:addictional_grid_down] * dimY

      bb_minX, bb_minY, bb_minZ = bb_min.to_a
      bb_maxX, bb_maxY, bb_maxZ = bb_max.to_a

      minX = bb_minX - distLeft
      minY = bb_minY - distDown
      maxX = bb_maxX + distRight
      maxY = bb_maxY + distUp
      reqHeight = bb_maxZ * 2.5

      domX = maxX - minX
      domY = maxY - minY

      numX = (domX / dimX).round(0)
      numY = (domY / dimY).round(0)
      numZ = (reqHeight / dimZ).round(0)

      maxX = minX + (numX * dimX)
      maxY = minY + (numY * dimY)

      gZ = []
      firstGrid = dimZ / 5

      grid = 0
      numZ += 4 if other_info[:telescope] == 0.0

      0.step(numZ + 1) do |i|
        if other_info[:telescope] == 0.0
          if i <= 5
            if i == 0
              grid = 0
            elsif i == 1
              grid = firstGrid / 2
            else
              grid = (i * firstGrid) - (firstGrid / 2)
            end
          else
            grid = ((i - 4) * dimZ) - (dimZ / 2)
          end
        else
          puts "Telescope: #{other_info[:telescope]}"
          if i == 0
            grid = 0
          elsif i == 1 || grid <= other_info[:startTelescopeHeigth].m
            grid = (i * dimZ) - (dimZ / 2)
          else
            gz = dimZ
            my_dimZ = dimZ + (dimZ * other_info[:telescope].m / 100)
            grid = grid + (my_dimZ + gz) / 2
          end
        end
        if grid != 0
          gZ << grid
        end
      end

      other_info[:numX] = numX
      other_info[:numY] = numY
      other_info[:numZ] = numZ
      other_info[:minX] = minX
      other_info[:minY] = minY

      @repartition_z = gZ.map { |num| num.to_m }

    end


    def grid_preview_xy(base)

      0.step(other_info[:numX]) do |i|
        0.step(other_info[:numY]) do |j|
          self.grid_2d_points << Geom::Point3d.new((i * dimX) + other_info[:minX], (j * dimY) + other_info[:minY], base)
        end
      end

    end


    def grid_preview_3d

      0.step(other_info[:numX]) do |i|
        0.step(other_info[:numY]) do |j|
          repartition_z.each do |z_element|
            self.grid_3d_points << Geom::Point3d.new((i * dimX) + other_info[:minX], (j * dimY) + other_info[:minY], z_element.m)
          end
        end
      end

      grid_3d_points

    end


    def base_matrix_3d(item)

        layer = []
        repartition_z.each do
          column = []
          0.step(other_info[:numY]) do
            row = []
            0.step(other_info[:numX]) do
              row << item
            end
            column << row
          end
          layer << column
        end

        layer

      end


      def base_matrix_2d(item)

          column = []
          0.step(other_info[:numY]) do
            row = []
            0.step(other_info[:numX]) do
              row << item
            end
            column << row
          end

          column

        end

      def self.merge_2d(matrix)
        new_matrix = []
        matrix.transpose.each do |column|
          row = column.transpose.map { |el| el.max }
          new_matrix << row
        end
        new_matrix
      end


      def self.get_envimet_matrix(matrix)
        text = ""
        matrix.reverse.each do |column|
          text << column.join(',')
          text += "§"
        end
        text
      end

  end

end
