require 'sketchup.rb'
require_relative 'geometry/grid'
require_relative 'geometry/building'
require_relative 'geometry/location'
require_relative 'geometry/object2d'
require_relative 'preparation/preparation'
require_relative 'utils/utils'
require_relative 'ui/ui'
require_relative 'io/inx'

module Envimet::EnvimetInx

  unless file_loaded?(__FILE__)

    @@preparation = Preparation.new

    toolbar = UI::Toolbar.new("ENVI_MET")

    cmd = UI::Command.new("Envimet inx") { self.run_html_window(File.join(PLUGIN_DIR, "ui/html/main.html")) }
    cmd.small_icon = "res/logo.png"
    cmd.large_icon = "res/logo.png"
    cmd.tooltip = "ENVI_MET inx"
    cmd.status_bar_text = "Use this tool to create Envimet inx basic file. Use correct layer to add solid gemeotries."
    toolbar.add_item(cmd)

    toolbar.show
    
    file_loaded(__FILE__)
  end

end
