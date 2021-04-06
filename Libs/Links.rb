
# encoding: UTF-8

class Links

    # Links::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Links.sqlite3"
    end

    # Links::issueLink(node1uuid, node2uuid)
    def self.issueLink(node1uuid, node2uuid)
        return if node1uuid == node2uuid
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node1uuid, node2uuid]
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node2uuid, node1uuid]
        db.execute "insert into _network_ (_node1_, _node2_) values (?,?)", [node1uuid, node2uuid]
        db.commit 
        db.close
    end

    # Links::deleteLink(node1uuid, node2uuid)
    def self.deleteLink(node1uuid, node2uuid)
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node1uuid, node2uuid]
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node2uuid, node1uuid]
        db.close
    end

    # Links::getLinkedUUIDs(uuid)
    def self.getLinkedUUIDs(uuid)
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _network_ where _node1_=?", [uuid]) do |row|
            answer << row['_node2_']
        end
        db.execute("select * from _network_ where _node2_=?", [uuid]) do |row|
            answer << row['_node1_']
        end
        db.close
        answer.uniq
    end

    # --------------------------------------------------

    # Links::linkObjects(object1, object2)
    def self.linkObjects(object1, object2)
        Links::issueLink(object1["uuid"], object2["uuid"])
    end

    # Links::unlinkObjects(object1, object2)
    def self.unlinkObjects(object1, object2)
        Links::deleteLink(object1["uuid"], object2["uuid"])
    end

    # Links::areLinkedObjects(object1, object2)
    def self.areLinkedObjects(object1, object2)
        Links::getLinkedUUIDs(object1["uuid"]).include?(object2["uuid"])
    end

    # Links::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        Links::getLinkedUUIDs(object["uuid"]).map{|uuid| Patricia::getNodeByUUIDOrNull(uuid) }.compact
    end

    # Links::getLinkedObjectsInTimeOrder(object)
    def self.getLinkedObjectsInTimeOrder(object)
        Links::getLinkedObjects(object).sort{|o1, o2| o1["unixtime"]<=>o2["unixtime"] }
    end

    # Links::removeElementOccurences(uuid)
    def self.removeElementOccurences(uuid)
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _network_ where _node1_=?", [uuid]
        db.execute "delete from _network_ where _node2_=?", [uuid]
        db.close
    end

    # --------------------------------------------------

    # Links::selectOneOfTheLinkedNodeOrNull(node)
    def self.selectOneOfTheLinkedNodeOrNull(node)
        related = Links::getLinkedObjectsInTimeOrder(node)
        return if related.empty?
        LucilleCore::selectEntityFromListOfEntitiesOrNull("related", related, lambda{|node| Patricia::toString(node) })
    end

    # Links::reshape(node1, nodes, node2)
    def self.reshape(node1, nodes, node2)
        # This function takes a node1 and some nodes and a node2 and detach all the nodes from 
        # node1 and attach them to node2
        nodes.each{|n|
            Links::linkObjects(node2, n)
            Links::unlinkObjects(node1, n)
        }
    end

    # Links::architectAncestorsPathsToNode(node)
    def self.architectAncestorsPathsToNode(node)
        # This function takes a node and proposes the user to present paths and ensure that the paths exist
        # While resolving the navigation nodes names we use 
        puts "node: #{Patricia::toString(node)}"

        loop {
            input = LucilleCore::askQuestionAnswerAsString("ancestors path (use '>' as separator) (empty to close): ")
            break if input == ""
            descriptions = input.split(">").map{|d| d.strip }.select{|d| d.size > 0 }
            pairs = descriptions.zip(descriptions[1, descriptions.size])
            pairs.each{|pair|
                description1 = pair[0]
                description2 = pair[1] ? pair[1] : "node"
                puts "Making the link from #{description1} to #{description2}"
                LucilleCore::pressEnterToContinue()
                node1 = NavigationPoints::architectureNavigationPointGivenDescriptionOrNull(description1)
                return if node1.nil?
                node2  = (description2 != "node") ? NavigationPoints::architectureNavigationPointGivenDescriptionOrNull(description2) : node
                return if node2.nil?
                Links::linkObjects(node1, node2)
            }
        }
    end
end
