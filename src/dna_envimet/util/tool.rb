module Envimet
  module EnvimetInx
    
    class GridTool

      def activate
	  	@points = []
        @mouse_pt = Sketchup::InputPoint.new
		@grid_min_max = []
        update_ui
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        update_ui
        view.invalidate
      end

      def onCancel(reason, view)
        reset_tool
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        update_ui
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
		if @points.length == 0
	      @mouse_pt.pick(view, x, y)
		  @points << @mouse_pt.position if is_valid_pt?(@mouse_pt)
		elsif @points.length < 2
		  @points << @mouse_pt.position if @mouse_pt.pick(view, x, y, @mouse_pt) && is_valid_pt?(@mouse_pt)
		end
        update_ui
        view.invalidate
      end

      CURSOR_POINT = UI.create_cursor(File.join(PLUGIN_DIR, "res/tool_icon.png"), 0, 0)
      def onSetCursor
        UI.set_cursor(CURSOR_POINT)
      end
 
	  def getExtents
        bb = Geom::BoundingBox.new
        bb.add(@points) unless @points.empty?
        bb
      end

      def draw(view)
        draw_preview(view)
		@mouse_pt.draw(view) if @mouse_pt.display?
      end

      def onUserText(text, view)
        begin
          EnvimetInx.set_envimet_grid(*@grid_min_max, text) if is_input_text_correct?(text)
        rescue ArgumentError
          UI.messagebox("Invalid integer.  Type one of following integer: 1 = Equidistant; 2 = Telescopic; 3 = Combined.")
        end
      end

      private
      def update_ui
        if @points.empty?
          Sketchup.status_text = "Select first point."
		elsif @points.size == 1
          Sketchup.status_text = "Select second point."
		elsif @points.size == 2
		  Sketchup.status_text = "Select grid type. Type one of following integer: 1 = Equidistant; 2 = Telescopic; 3 = Combined."
        end
      end
	  
	  def is_input_text_correct?(text)
	    text.size == 1 && ["1","2","3"].any?(text)
	  end

      def reset_tool
        @mouse_pt.clear
		@points = []
		@grid_min_max = []
        update_ui
      end

      def is_valid_pt?(input_point)
        input_point.valid?
      end

	  def draw_preview(view)
        pts = @points
		color = "red"
        style = 1
        size = 10
        pts.each { |pt| view.draw_points(pt, size, style, color) }
        return unless pts.size == 2
		
        view.drawing_color = Sketchup::Color.new(255, 0, 0, 64)
        view.line_width = 2
        view.line_stipple = '_'
		pt1 = pts.first
		pt2 = Geom::Point3d.new( pts.last.x, pts.first.y, 0)
		pt3 = pts.last
		pt4 = Geom::Point3d.new( pts.first.x, pts.last.y, 0)
		
        view.draw(GL_LINE_LOOP, [pt1, pt2, pt3, pt4])
		
		set_bbox_from_points([pt1, pt2, pt3, pt4])
		
		view.draw(GL_LINES, [pt1, pt3])
      end
	   
	  def set_bbox_from_points(pts)
	    boundingbox = Geom::BoundingBox.new
		pts.each { |pt| boundingbox.add(pt) }
		@grid_min_max = [boundingbox.min, boundingbox.max]
	  end
	  
    end # end GridTool
  end # end EnvimetInx
end # end Envimet