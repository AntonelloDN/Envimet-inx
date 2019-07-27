# ---------------------------------------------------------
# Envimet INX: A basic plugin for Sketchup to write *.inx files of ENVI_MET 4.3.
# 
# Copyright (c) 2013-2019, Antonello Di Nunzio <antonellodinunzio@gmail.com> 
# Envimet INX is free software; you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
# 
# Envimet INX is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Envimet INX; If not, see <http://www.gnu.org/licenses/>.
# 
# @license GPL-3.0+ <http://spdx.org/licenses/GPL-3.0+>
# ---------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

module Envimet
  module EnvimetInx

    unless file_loaded?(__FILE__)

      PLUGIN_ID = File.basename(__FILE__, ".rb")
      PLUGIN_DIR = File.join(File.dirname(__FILE__), PLUGIN_ID)
      
      ex = SketchupExtension.new("Envimet INX", "dna_envimet/main")

      ex.description = "ENVI_MET inx basic plugin for SketchUp."
      ex.version     = "1.0.0"
      ex.copyright   = "GNU GPL V.3+"
      ex.creator     = "Antonello Di Nunzio, antonellodinunzio@gmail.com"

      Sketchup.register_extension(ex, true)

      file_loaded(__FILE__)
    end

  end
end
