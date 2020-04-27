module Envimet
  module EnvimetInx
    module Geometry
      class Terrain
        @@count = 0
        @@objects = []

        attr_accessor :other_info
        attr_reader :guid, :index, :name

        def initialize(name = " ", others = {})
          @name = name

          values = {}

          values.merge!(others)
          @other_info = values

          @guid = nil
          @@count += 1

          @index = @@count
        end

        def guid=(value)
          @guid = value if value
        end

        def to_s
          "<tr><th>ID</th><th>NAME</th></tr><tr><th>#{index}</th><th>#{name}</th></tr>"
        end

        def self.get_count
          @@count
        end

        # class method
        def self.get_by_group_guid(guid)
          terrain = @@objects.select { |ter| guid == ter.guid }
          terrain
        end

        def self.get_existing_guid
          existing_guid = @@objects.map { |terrain| terrain.guid }
          existing_guid
        end

        def self.delete_by_group_guid(guid)
          @@objects.delete_if { |ter| guid == ter.guid }
        end

        def self.add_terrain(terrain)
          @@objects << terrain if terrain.is_a?(Terrain) && !terrain.guid.nil?
        end

        def self.get_terrain
          @@objects
        end

        def self.set_index(objects)
          index_list = objects.grep(Geometry::Terrain).map { |obj| obj.index }
          unless index_list.empty?
            @@count = index_list.max
          end
        end

        def self.reset
          @@objects = []
          @@count = 0
        end
      end # end Terrain
    end # end Geometry
  end # end EnvimetInx
end # end Envimet
