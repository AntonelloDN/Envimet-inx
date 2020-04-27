module Envimet
  module EnvimetInx
    module Geometry
      class Grid
	  
	    @@objects = []

        FIRST_CELLS = 5
        GRID_TYPE = { "1" => :equidistant, "2" => :telescope, "3" => :combined }

        attr_reader :dimX, :dimY, :dimZ, :guid
        attr_accessor :other_info

        def initialize(dimX=3.0, dimY=3.0, dimZ=3.0, others = {})
          values = {
            addictional_grid_left:0,
            addictional_grid_right:0,
            addictional_grid_up:0,
            addictional_grid_down:0
          }

          values.merge!(others)

          @dimX = dimX.m
          @dimY = dimY.m
          @dimZ = dimZ.m
          @other_info = values
		  
		      @guid = nil
        end

        def to_s
		      "<tr><th>CELL SIZE</th><th>DIMENSION</th></tr><tr><th>#{dimX}, #{dimY}, #{dimZ}</th><th>#{other_info[:numX]+1}X, #{other_info[:numY]+1}Y, #{other_info[:numZ_cells]}Z</th></tr>"
        end

        def set_sequence_and_extension(bb_min, bb_max)
		      calculate_grid_xy(bb_min, bb_max)
		      height = []
		  
          case (other_info[:grid_type])
            when :equidistant
              other_info[:sequence] = get_equidistant_sequence(other_info[:numZ_cells]).map(&:to_f)
            when :telescope
              other_info[:sequence] = get_telescope_sequence(other_info[:numZ_cells]).map(&:to_f)
            when :combined
              other_info[:sequence] = get_combined_sequence(other_info[:numZ_cells]).map(&:to_f)
            else
              other_info[:sequence] = get_equidistant_sequence(other_info[:numZ_cells]).map(&:to_f)
          end
		  
		      other_info[:height] = other_info[:sequence].sum
        end
        
		
		    def set_x_axis
		      x_axis = []
		      0.step(other_info[:numX]) { |i| x_axis << (i * dimX) + other_info[:minX] }
		      other_info[:x_axis] = x_axis
		    end
		    
		    
		    def set_y_axis
		      y_axis = []
		      0.step(other_info[:numY]) { |j| y_axis << (j * dimY) + other_info[:minY] }
		      other_info[:y_axis] = y_axis
		    end
        
		
        def base_matrix_2d(item = nil)
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
        
		
        def self.merge_2d(matrix, default="")
          new_matrix = []
          matrix.transpose.each do |column|
		        row = []
            column.transpose.each do |el|
              temp = el.compact
			        item = default
			        item = temp.last unless temp.empty?
			        row << item
			      end
            new_matrix << row
          end
          new_matrix
        end
		
		
        def self.get_envimet_matrix(matrix)
		      text = "§"
          matrix.reverse.each do |column|
            text << column.join(',')
            text += "§"
          end
          text
        end
		
		
		    def guid=(value)
	        @guid = value if value
	      end
		
		    # class method
	      def self.get_by_group_guid(guid)
	        grid = @@objects.select { |grd| guid == grd.guid }
		    grid
          end
	      
	      def self.get_existing_guid
	        existing_guid = @@objects.map { |grid| grid.guid }
		    existing_guid
	      end
		  
	      def self.delete_by_group_guid(guid)
	        @@objects.delete_if { |grd| guid == grd.guid }
          end
	      
	      def self.add_grid(grid)
	        @@objects << grid if grid.is_a?(Grid) && !grid.guid.nil?
	      end
	      
	      def self.get_grid
	        @@objects
	      end
	    
		
        private
        def calculate_grid_xy(bb_min, bb_max)
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

          domX = maxX - minX
          domY = maxY - minY

          numX = (domX / dimX).round(0)
          numY = (domY / dimY).round(0)

          maxX = minX + (numX * dimX)
          maxY = minY + (numY * dimY)

          other_info[:numX] = numX
          other_info[:numY] = numY
          other_info[:minX] = minX
          other_info[:minY] = minY
		      other_info[:maxX] = maxX
          other_info[:maxY] = maxY
        end

        # Sequence z
        def get_equidistant_sequence(num_z_cell)
          base_cell = self.dimZ / FIRST_CELLS
          cell = self.dimZ
          sequence = []
          num_z_cell.times { |k| sequence[k] = (k < 5) ? base_cell : cell }
          sequence
        end
		
		
        def get_telescope_sequence(num_z_cell)
          cell = self.dimZ
          sequence = []
          val = cell

          num_z_cell.times do |k|
            if (val * k < other_info[:start_telescope_heigth])
              sequence[k] = cell;
            else
              sequence[k] = val + (val * other_info[:telescope] / 100);
              val = sequence[k];
            end
          end

          sequence
        end
        
		
        def get_combined_sequence(num_z_cell)
          equidistant_sequence = get_equidistant_sequence(FIRST_CELLS)
          telescopic_sequence = get_telescope_sequence(num_z_cell)
          telescopic_sequence.shift

          sequence = equidistant_sequence + telescopic_sequence

          sequence
        end
        
      end # end Grid
    end # end Geometry
  end # end EnvimetInx
end # end Envimet
