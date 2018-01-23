require "xml"

module XmlStreamer
  extend self

  def parse(io, listener)
    reader = XML::Reader.new(io)
    while reader.read
      case reader.node_type
      when XML::Type::ELEMENT_NODE
        tag_name = reader.name
        attributes = Hash(String, String).new
        if reader.has_attributes?
          reader.attributes_count.times do
            reader.move_to_next_attribute
            attributes[reader.name] = reader.value
          end
        end
        listener.tag_start(tag_name, attributes)
      when XML::Type::ELEMENT_DECL
        listener.tag_end(reader.name) { |result| yield result }
      when XML::Type::TEXT_NODE
        listener.text(reader.value)
      when XML::Type::CDATA_SECTION_NODE
        listener.cdata(reader.value) if listener.responds_to?(:cdata)
      end
    end
  end
end
