
# encoding: UTF-8

class Links

    # Links::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Links.sqlite3"
    end

    # Links::links()
    def self.links()
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _network_", []) do |row|
            answer << {
                "uuid1" => row['_node1_'],
                "uuid2" => row['_node2_']
            }
        end
        db.close
        answer
    end

    # Links::issueDirectedLink(node1uuid, node2uuid)
    def self.issueDirectedLink(node1uuid, node2uuid)
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

    # Links::getLinkedUUIDsParents(uuid)
    def self.getLinkedUUIDsParents(uuid)
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _network_ where _node2_=?", [uuid]) do |row|
            answer << row['_node1_']
        end
        db.close
        answer.uniq
    end

    # Links::getLinkedUUIDsChildren(uuid)
    def self.getLinkedUUIDsChildren(uuid)
        db = SQLite3::Database.new(Links::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _network_ where _node1_=?", [uuid]) do |row|
            answer << row['_node2_']
        end
        db.close
        answer.uniq
    end

    # --------------------------------------------------

    # Links::linkObjectsDirectionaly(object1, object2)
    def self.linkObjectsDirectionaly(object1, object2)
        Links::issueDirectedLink(object1["uuid"], object2["uuid"])
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
        Links::getLinkedUUIDs(object["uuid"]).map{|uuid| NereidInterface::getElementOrNull(uuid) }.compact
    end

    # Links::getLinkedObjectsParents(object)
    def self.getLinkedObjectsParents(object)
        Links::getLinkedUUIDsParents(object["uuid"]).map{|uuid| NereidInterface::getElementOrNull(uuid) }.compact
    end

    # Links::getLinkedObjectsChildren(object)
    def self.getLinkedObjectsChildren(object)
        Links::getLinkedUUIDsChildren(object["uuid"]).map{|uuid| NereidInterface::getElementOrNull(uuid) }.compact
    end

    # Links::getLinkedObjectsInTimeOrder(object)
    def self.getLinkedObjectsInTimeOrder(object)
        Links::getLinkedObjects(object).sort{|o1, o2| o1["unixtime"]<=>o2["unixtime"] }
    end

    # --------------------------------------------------

    # Links::reshapeDirectionaly(node1, nodes, node2)
    def self.reshapeDirectionaly(node1, nodes, node2)
        # This function takes a node1 and some nodes and a node2 and detach all the nodes from 
        # node1 and attach them to node2
        nodes.each{|n|
            Links::linkObjectsDirectionaly(node2, n)
            Links::unlinkObjects(node1, n)
        }
    end
end
