module Envimet::EnvimetInx

  def self.create_group_by_layer(layer, copy=false)

    model = Sketchup.active_model
    model.start_operation('Group_by_layer', true)

    model.active_layer = layer
    entities = model.active_entities
    selection = model.selection
    entities.each{|e| selection.add(e) if e.layer.name == layer}

    selection_array = selection.to_a
    selection.clear
    group = entities.add_group(selection_array)

    if copy
      copy_entities = group.copy
    end

    model.commit_operation

  end


  def self.explode_group_by_layer(layer)

    model = Sketchup.active_model
    model.start_operation('Explode_group_by_layer', true)

    model.active_layer = layer
    entities = model.active_entities
    selection = model.selection
    entities.each{|e| selection.add(e) if e.layer.name == layer && e.is_a?(Sketchup::Group)}
    selection.to_a.each{ |group| group.explode }
    selection.clear

    model.commit_operation

  end


  def self.create_boundary_box(pt_min, pt_max)

    model = Sketchup.active_model
    entities = model.active_entities
    model.active_layer = "grid_representation"

    pt1 = pt_min
    pt8 = pt_max

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

    entities.add_group(lines)

  end


  def self.point_comparison_validation(pt1, pt2)
    (pt1.x == pt2.x && pt1.y == pt2.y) || (pt1.x == pt2.x && pt1.z == pt2.z) || (pt1.y == pt2.y && pt1.z == pt2.z)
  end


  def self.get_bbox_by_layer(layers)

    model = Sketchup.active_model
    entities = model.active_entities
    selection = model.selection
    selection.clear
    entities.each{|e| selection.add(e) if layers.include?(e.layer.name)}

    positions = []

    boundingbox = Geom::BoundingBox.new
    selection.each { |item| positions << item.vertices.map{|v| v.position} }

    positions.flatten!
    positions.each {|item| boundingbox.add(item)}

    selection.clear
    return boundingbox

  end


  def self.hide_all_except(layer)

    hide_except = lambda { |l| l.visible = false unless l.name == layer }
    model = Sketchup.active_model
    model.active_layer = layer
    model.layers.each { |l| hide_except.call(l) }

  end


  def self.show_layers

    show_layer = lambda { |l| l.visible = true }
    model = Sketchup.active_model
    model.layers.each { |l| show_layer.call(l) }

  end


  def self.voxels_3d(grid, layer)

    model = Sketchup.active_model
    entities = model.active_entities

    self.hide_all_except(layer)

    points_inside_volume = []
    grid.grid_3d_points.each do |pt|
      count = 0
      rays = [[pt, Geom::Vector3d.new(1, 0, 0)], [pt, Geom::Vector3d.new(0, 1, 0)], [pt, Geom::Vector3d.new(0, 0, 1)], [pt, Geom::Vector3d.new(-1, 0, 0)], [pt, Geom::Vector3d.new(0, -1, 0)], [pt, Geom::Vector3d.new(0, 0, -1)]]
      rays.each do |ray|
        items = model.raytest(ray, true)

        if items.nil?
          break
        end

        count +=1

      end

      if count == 6
        points_inside_volume << pt
      end

    end

    model.active_layer = "Layer0"
    points_inside_volume
  end

  def self.voxels_2d(grid, layer, positive = true)

    model = Sketchup.active_model
    entities = model.active_entities

    self.hide_all_except(layer)

    z_val = positive ? 1 : -1

    points_hit_geometry, pt_intersection = [], []
    grid.grid_2d_points.each do |pt|

      ray = [pt, Geom::Vector3d.new(0, 0, z_val)]
      items = model.raytest(ray, true)

      unless items.nil?
        points_hit_geometry << pt
        pt_intersection << items[0]
      end

    end

    model.active_layer = "Layer0"

    return points_hit_geometry, pt_intersection

  end

end
