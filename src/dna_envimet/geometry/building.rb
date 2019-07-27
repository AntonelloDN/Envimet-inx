module Envimet::EnvimetInx

  class Building

    attr_accessor :matrix, :building_flag_and_nr, :wall_material, :roof_material

    def initialize(index)

      @wall_material = "000000"
      @roof_material = "000000"
      @building_flag_and_nr = ""
      @matrix = []
      @index = index

    end

    def create_voxel_matrix(voxel_points, grid)

      self.matrix = grid.base_matrix_3d(0)

      voxel_points.each do |pt|
        valX = ((pt.x - grid.other_info[:minX]) / grid.dimX).round(0)
        valY = ((pt.y - grid.other_info[:minY]) / grid.dimY).round(0)
        valZ = grid.repartition_z.index(pt.z.to_m)

        valX = valX.to_i
        valY = valY.to_i
        valZ = valZ.to_i

        self.matrix[valZ][valY][valX] = @index
        self.building_flag_and_nr += "#{valX},#{valY},#{valZ},1,#{@index}§"

      end

    end


    def self.merge_matrix(study_area, context, op_proc)

      matrix = []
      (study_area.length).times do |z|
        column = []
        (study_area[z].length).times do |j|
          row = []
          (study_area[z][j].length).times  do |i|
            element1, element2 = study_area[z][j][i], context[z][j][i]
        	  val = op_proc.call(element1, element2)
        	  row << val
          end
      	  column << row
        end
        matrix << column
      end

      matrix

    end


    def self.set_materials(matrix, matWall, matRoof)
      
      wall_db = ""

      (matrix.length).times do |k|
        (matrix[k].length).times do |j|
          (matrix[k][j].length).times do |i|
            if matrix[k][j][i] != 0
              index = matrix[k][j][i] - 1
              if matrix[k][j][i-1] == 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] == 0
                wall_db += "#{i},#{j},#{k},#{matWall[index]},#{matWall[index]},#{matRoof[index]}§"
              elsif matrix[k][j][i-1] == 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] == 0
                wall_db += "#{i},#{j},#{k},#{matWall[index]},,#{matRoof[index]}§"
              elsif matrix[k][j][i-1] != 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] == 0
                wall_db += "#{i},#{j},#{k},,#{matWall[index]},#{matRoof[index]}§"
              elsif matrix[k][j][i-1] == 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] != 0
                wall_db += "#{i},#{j},#{k},#{matWall[index]},#{matWall[index]},§"
              elsif matrix[k][j][i-1] == 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] != 0
                wall_db += "#{i},#{j},#{k},#{matWall[index]},,§"
              elsif matrix[k][j][i-1] != 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] != 0
                wall_db += "#{i},#{j},#{k},,#{matWall[index]},§"
              elsif matrix[k][j][i-1] != 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] == 0
                wall_db += "#{i},#{j},#{k},,,#{matRoof[index]}§"
              end
            else
              if matrix[k][j][i-1] != 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] == 0
                index = matrix[k][j][i-1] - 1
                wall_db += "#{i},#{j},#{k},#{matWall[index]},,§"
              elsif matrix[k][j][i-1] == 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] == 0
                index = matrix[k][j-1][i] - 1
                wall_db += "#{i},#{j},#{k},,#{matWall[index]},§"
              elsif matrix[k][j][i-1] == 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] != 0
                index = matrix[k-1][j][i] - 1
                wall_db += "#{i},#{j},#{k},,,#{matRoof[index]}§"
              elsif matrix[k][j][i-1] != 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] == 0
                index = matrix[k][j-1][i] - 1
                wall_db += "#{i},#{j},#{k},#{matWall[index]},#{matWall[index]},§"
              elsif matrix[k][j][i-1] != 0 && matrix[k][j-1][i] == 0 && matrix[k-1][j][i] != 0
                indexW = matrix[k][j][i-1] - 1
                indexR = matrix[k-1][j][i] - 1
                wall_db += "#{i},#{j},#{k},#{matWall[indexW]},,#{matRoof[indexR]}§"
              elsif matrix[k][j][i-1] == 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] != 0
                indexW = matrix[k][j-1][i] - 1
                indexR = matrix[k-1][j][i] - 1
                wall_db += "#{i},#{j},#{k},,#{matWall[indexW]},#{matRoof[indexR]}§"
              elsif matrix[k][j][i-1] != 0 && matrix[k][j-1][i] != 0 && matrix[k-1][j][i] != 0
                indexW = matrix[k][j-1][i] -1
                indexR = matrix[k-1][j][i] -1
                wall_db += "#{i},#{j},#{k},#{matWall[indexW]},#{matWall[indexW]},#{matRoof[indexR]}§"
              end
            end
          end
        end
      end
      wall_db
    end

  end

end
