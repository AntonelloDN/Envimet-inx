module Envimet
  module EnvimetInx
    module IO
      module Library
        require "rexml/document"
        include REXML

        STANDARD_ENVIMET_PATH = File.join(File.dirname(__FILE__), "db/db_path.txt")
        SYS_LIBRARY = "sys.basedata/database.edb"
        USER_LIBRARY = "sys.userdata/userdatabase.edb"

        def self.get_values_from_doc_by_tag(doc, tag)
          values = []
          doc.root.each_element(tag) { |id| values << id.text.gsub(" ", "") }
          values
        end

        def self.get_library_path_from_plugin(path)
          result = nil
          File.open(path, "r").each { |line| result = line }
          result
        end

        def self.get_clean_text(path)
          lines = []
          File.open(path, "r").each do |line|
            line.gsub!("&", "_")
            lines << line if line.force_encoding("UTF-8").ascii_only?
          end
          lines.join
        end

        def self.get_envimet_library(path)
          text = self.get_clean_text(path)
          begin
            doc = Document.new(text)
            soil = self.get_values_from_doc_by_tag(doc, "//PROFILE/ID")
            wall = self.get_values_from_doc_by_tag(doc, "//WALL/ID")
            greening = self.get_values_from_doc_by_tag(doc, "//GREENING/ID")
            plant2d = self.get_values_from_doc_by_tag(doc, "//PLANT/ID")
            plant3d = self.get_values_from_doc_by_tag(doc, "//PLANT3D/ID")
            source = self.get_values_from_doc_by_tag(doc, "//SOURCE/ID")

            return { soil: soil, wall: wall, plant2d: plant2d, plant3d: plant3d, greening: greening, source: source }
          rescue RuntimeError => msg
            return
          end
        end
      end # end Library
    end # end IO
  end # end EnvimetInx
end # end Envimet
