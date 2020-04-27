["preparation/preparation",
 "preparation/serialize",
 "geometry/building",
 "geometry/plant2d",
 "geometry/plant3d",
 "geometry/soil",
 "geometry/terrain",
 "geometry/grid",
 "geometry/layers",
 "geometry/receptor",
 "geometry/source",
 "settings/location",
 "util/util",
 "util/tool",
 "ui/messagebox",
 "io/library",
 "command",
 "util/computation",
 "io/inx"].each { |path| Sketchup::require(File.join(File.dirname(__FILE__), path)) }

module Envimet
  module EnvimetInx
    def self.activate_grid_tool
      if Util.layer_exist?(SkpLayers::GRID)
        Sketchup.active_model.select_tool(GridTool.new)
      else
        UI.messagebox("Please, create Envimet Layers")
      end
    end

    unless file_loaded?(__FILE__)
      Sketchup.add_observer(EnvimetAppObserver.new)

      @@preparation = Preparation.new
      @@preparation.add_value("library", { soil: [], wall: [], plant2d: [], greening: [], plant3d: [], source: [] })
      begin
        import_library # import lib in silent mode
      rescue SystemCallError => e
        puts "Library missing!"
      end

      toolbar = UI::Toolbar.new "ENVI_MET Inx"

      cmd = UI::Command.new("Create Envimet Layers") { set_envimet_layers }
      cmd.tooltip = "Create Envimet Layers"
      cmd.status_bar_text = "Use this command to create Envimet Layers.\n'in_' layers should contain geometries to trasform into Envimet objects.\n'out_' layers contain Envimet objects."
      cmd.small_icon = cmd.large_icon = "res/icon/layers.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Location") { set_envimet_location }
      cmd.tooltip = "Create Envimet Location"
      cmd.status_bar_text = "Use this command to create Envimet Location.\nIt reads automatically Geo-location of Sketchup, only Timezone need to be setted manually."
      cmd.small_icon = cmd.large_icon = "res/icon/location.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Grid") do |i|
        Geometry::Grid.get_grid.select!(&(Util::CLEAN_GROUP))
        unless Geometry::Grid.get_grid.empty?
          UI.messagebox("Envimet Grid already exist.\nIf you want to delete it or change it select current envimet grid and click on 'Delete Envimet Object' command.")
        else
          activate_grid_tool
        end
      end
      cmd.tooltip = "Create Envimet Grid"
      cmd.status_bar_text = "Use this command to create Envimet Grid.\nFollow instructions in status bar."
      cmd.small_icon = cmd.large_icon = "res/icon/grid.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Soil") { set_envimet_soil }
      cmd.tooltip = "Create Envimet Soil"
      cmd.status_bar_text = "Use this command to create Envimet Soil."
      cmd.small_icon = cmd.large_icon = "res/icon/soil.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Plant2d") { set_envimet_2d_plant }
      cmd.tooltip = "Create Envimet Plant2d"
      cmd.status_bar_text = "Use this command to create Envimet Plant2d."
      cmd.small_icon = cmd.large_icon = "res/icon/plant2d.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Plant3d") { set_envimet_3d_plant }
      cmd.tooltip = "Create Envimet Plant3d"
      cmd.status_bar_text = "Use this command to create Envimet Plant3d."
      cmd.small_icon = cmd.large_icon = "res/icon/plant3d.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Terrain") { set_envimet_terrain }
      cmd.tooltip = "Create Envimet Terrain"
      cmd.status_bar_text = "Use this command to create Envimet Terrain."
      cmd.small_icon = cmd.large_icon = "res/icon/terrain.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Building") { set_envimet_building }
      cmd.tooltip = "Create Envimet Building"
      cmd.status_bar_text = "Use this command to create Envimet Building."
      cmd.small_icon = cmd.large_icon = "res/icon/building.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Receptor Group") { set_envimet_receptor }
      cmd.tooltip = "Create Envimet Receptor Group"
      cmd.status_bar_text = "Use this command to create Envimet Receptor.\nA receptor is like a digital microclimatic station. One pixel for each of them is enough."
      cmd.small_icon = cmd.large_icon = "res/icon/receptor.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Create Envimet Source") { set_envimet_source }
      cmd.tooltip = "Create Envimet Source"
      cmd.status_bar_text = "Use this command to create Envimet Source.\nEnvimet Source are used for particles emissions."
      cmd.small_icon = cmd.large_icon = "res/icon/source.png"
      toolbar = toolbar.add_item(cmd)

      toolbar.add_separator

      cmd = UI::Command.new("Info Envimet Object") { get_envimet_entity_info }
      cmd.tooltip = "Info Envimet Object"
      cmd.status_bar_text = "Use this command to get information about Envimet objects.\nYou can also use it to check if Envimet objects are active (see. SKPINX)."
      cmd.small_icon = cmd.large_icon = "res/icon/info.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Delete Envimet Object") { delete_envimet_object }
      cmd.tooltip = "Delete Envimet Object"
      cmd.status_bar_text = "Use this command to delete Envimet objects.\nOnly Envimet object will be deleted and not Sketchup geometries."
      cmd.small_icon = cmd.large_icon = "res/icon/delete.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Export Envimet Objects") { export_envimet_objects }
      cmd.tooltip = "Export Envimet Objects"
      cmd.status_bar_text = "Use this command to export Envimet objects.\nOnly Envimet objects will be exported. Geometries will continue to be stored into SKP file."
      cmd.small_icon = cmd.large_icon = "res/icon/export.png"
      toolbar = toolbar.add_item(cmd)

      cmd = UI::Command.new("Import Envimet Objects") { import_envimet_objects }
      cmd.tooltip = "Import Envimet Objects"
      cmd.status_bar_text = "Use this command to import Envimet objects.\nSKPINX contains all Envimet objects information. It will work only if SKPINX match all active Sketchup geometries.\nUse 'Info Envimet Object' with some elements to check if importation is run successfully"
      cmd.small_icon = cmd.large_icon = "res/icon/import.png"
      toolbar = toolbar.add_item(cmd)

      toolbar.add_separator

      cmd = UI::Command.new("Install Envimet Material Library") { install_envimet_standard_db }
      cmd.tooltip = "Install Envimet Material Library"
      cmd.status_bar_text = "Use this command to install Envimet Material Library.\nYou can uninstall and install libraries many times whenever you want.\nYou can install envimet sys library OR envimet user library.\nProject library is not supported but you can use 'free form' inputs if you uninstall library."
      cmd.small_icon = cmd.large_icon = "res/icon/library.png"
      toolbar = toolbar.add_item(cmd)

      toolbar.add_separator

      cmd = UI::Command.new("Write Inx File") do
        set_geometries
        write_inx_file
      end
      cmd.tooltip = "Write Inx File"
      cmd.status_bar_text = "Use this command to write INX file of ENVI-Met.\nSave files into current ENVI-Met project folder to retrieve them with ENVIGuide."
      cmd.small_icon = cmd.large_icon = "res/icon/inx.png"
      toolbar = toolbar.add_item(cmd)

      toolbar.show

      file_loaded(__FILE__)
    end
  end # end EnvimetInx
end # end Envimet
