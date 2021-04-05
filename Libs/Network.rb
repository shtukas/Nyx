
# encoding: UTF-8

class Network

    # Network::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Network.sqlite3"
    end

    # Network::issueLink(node1uuid, node2uuid)
    def self.issueLink(node1uuid, node2uuid)
        return if node1uuid == node2uuid
        db = SQLite3::Database.new(Network::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node1uuid, node2uuid]
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node2uuid, node1uuid]
        db.execute "insert into _network_ (_node1_, _node2_) values (?,?)", [node1uuid, node2uuid]
        db.commit 
        db.close
    end

    # Network::deleteLink(node1uuid, node2uuid)
    def self.deleteLink(node1uuid, node2uuid)
        db = SQLite3::Database.new(Network::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node1uuid, node2uuid]
        db.execute "delete from _network_ where _node1_=? and _node2_=?", [node2uuid, node1uuid]
        db.close
    end

    # Network::getLinkedUUIDs(uuid)
    def self.getLinkedUUIDs(uuid)
        db = SQLite3::Database.new(Network::databasePath())
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

    # Network::link(object1, object2)
    def self.link(object1, object2)
        Network::issueLink(object1["uuid"], object2["uuid"])
    end

    # Network::unlink(object1, object2)
    def self.unlink(object1, object2)
        Network::deleteLink(object1["uuid"], object2["uuid"])
    end

    # Network::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        Network::getLinkedUUIDs(object["uuid"]).map{|uuid| Patricia::getNodeByUUIDOrNull(uuid) }.compact
    end

    # Network::getLinkedObjectsInTimeOrder(object)
    def self.getLinkedObjectsInTimeOrder(object)
        Network::getLinkedObjects(object).sort{|o1, o2| o1["unixtime"]<=>o2["unixtime"] }
    end

    # Network::removeElementOccurences(uuid)
    def self.removeElementOccurences(uuid)
        db = SQLite3::Database.new(Network::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _network_ where _node1_=?", [uuid]
        db.execute "delete from _network_ where _node2_=?", [uuid]
        db.close
    end

    # --------------------------------------------------

    # Network::reshape(node1, nodes, node2)
    def self.reshape(node1, nodes, node2)
        # This function takes a node1 and some nodes and a node2 and detach all the nodes from 
        # node1 and attach them to node2
        nodes.each{|n|
            Network::link(node2, n)
            Network::unlink(node1, n)
        }
    end
end
