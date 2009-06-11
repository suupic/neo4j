module Neo4j
  module Relationships

    # Enables finding relationships for one node
    #
    class RelationshipTraverser
      include Enumerable

      attr_reader :internal_node

      def initialize(internal_node)
        @internal_node = internal_node
        @direction = org.neo4j.api.core.Direction::BOTH
      end

      def outgoing(type = nil)
        @type = type
        @direction = org.neo4j.api.core.Direction::OUTGOING
        self
      end

      def incoming(type = nil)
        @type = type
        @direction = org.neo4j.api.core.Direction::INCOMING
        self
      end

      def  both(type = nil)
        @type = type
        @direction = org.neo4j.api.core.Direction::BOTH
        self
      end

      def empty?
        Neo4j::Transaction.run {!iterator.hasNext}
      end

      # Return the first relationship or nil
      #
      def first
        iter = iterator
        return nil unless iter.hasNext
        return Neo4j.instance.load_relationship(iter.next)
      end

      #
      # Returns the relationship object to the other node.
      #
      def [](other_node)
        find {|r| r.end_node.neo_node_id == other_node.neo_node_id}
      end



      def each
        Neo4j::Transaction.run do
          iter = iterator
          while (iter.hasNext) do
            n = iter.next
            yield Neo4j.instance.load_relationship(n)
          end
        end
      end

      def nodes
        RelationshipsEnumeration.new(self)
      end

      def iterator
        # if type is nil then we traverse all relationship types of depth one
        return @internal_node.getRelationships(@direction).iterator if @type.nil?
        return @internal_node.getRelationships(RelationshipType.instance(@type), @direction).iterator unless @type.nil?
      end

      def to_s
        "RelationshipTraverser [direction=#{@direction}, type=#{@type}]"
      end

      # Used from RelationshipTraverser when traversing nodes instead of relationships.
      #
      class RelationshipsEnumeration
        include Enumerable

        def initialize(relationships)
          @relationships = relationships
        end

        def first
          iter = @relationships.iterator
          return nil unless iter.hasNext()
          rel = Neo4j.instance.load_relationship(iter.next)
          rel.other_node(@relationships.internal_node)
        end
        
        def each
          @relationships.each do |relationship|
            yield relationship.other_node(@relationships.internal_node)
          end
        end
      end

    end

  
  end
end