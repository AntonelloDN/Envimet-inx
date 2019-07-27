module Envimet::EnvimetInx

  require_relative 'fnc_cmd'

  def self.run_html_window(html)

    properties = {
    :dialog_title => "Envimet",
    :style => UI::HtmlDialog::STYLE_DIALOG,
    :height => 180,
    :width => 700
    }

    dialog = UI::HtmlDialog.new(properties)
    dialog.set_file(html)

    dialog.add_action_callback('calculateLayers') { |action_context|
      self.create_envimet_layers
    }
    dialog.add_action_callback('calculateLocation') { |action_context|
      self.set_envimet_location
    }
    dialog.add_action_callback('calculateGrid') { |action_context|
      self.set_envimet_grid
    }
    dialog.add_action_callback('calculateBuilding') { |action_context|
      self.set_envimet_building
    }
    dialog.add_action_callback('calculatePlant2d') { |action_context|
      self.set_plant2d
    }
    dialog.add_action_callback('writeInx') { |action_context|
      self.write_file
    }
    dialog.center
    dialog.show

  end

end
