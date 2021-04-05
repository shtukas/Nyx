
# encoding: UTF-8

class NavigationPoints

    # NavigationPoints::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/NavigationPoints.sqlite3"
    end

    # ------------------------------------------------
    # Database

    # NavigationPoints::issueNewNavigationPoint(uuid, type, description)
    def self.issueNewNavigationPoint(uuid, type, description)
        db = SQLite3::Database.new(NavigationPoints::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _navigationpoints_ where _uuid_=?", [uuid]
        db.execute "insert into _navigationpoints_ (_uuid_, _unixtime_, _type_, _description_) values (?,?,?,?)", [uuid, Time.new.to_i, type, description]
        db.commit 
        db.close
    end

    # NavigationPoints::updateNavigationPointDescription(uuid, description)
    def self.updateNavigationPointDescription(uuid, description)
        db = SQLite3::Database.new(NavigationPoints::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "update _navigationpoints_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NavigationPoints::getNavigationPoints()
    def self.getNavigationPoints()
        db = SQLite3::Database.new(NavigationPoints::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _navigationpoints_", []) do |row|
            answer << {
                "uuid"           => row['_uuid_'],
                "unixtime"       => row['_unixtime_'],
                "identifier1"    => "103df1ac-2e73-4bf1-a786-afd4092161d4", # Indicates a classifier declaration
                "type"           => row['_type_'],
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # NavigationPoints::getNavigationPointByUUIDOrNull(uuid)
    def self.getNavigationPointByUUIDOrNull(uuid)
        db = SQLite3::Database.new(NavigationPoints::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _navigationpoints_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"           => row['_uuid_'],
                "unixtime"       => row['_unixtime_'],
                "identifier1"    => "103df1ac-2e73-4bf1-a786-afd4092161d4", # Indicates a classifier declaration
                "type"           => row['_type_'],
                "description"    => row['_description_']
            }
        end
        db.close
        answer
    end

    # NavigationPoints::destroy(navpoint)
    def self.destroy(navpoint)
        db = SQLite3::Database.new(NavigationPoints::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _navigationpoints_ where _uuid_=?", [navpoint["uuid"]]
        db.commit 
        db.close
    end
    
    # ------------------------------------------------

    # NavigationPoints::typeXs()
    def self.typeXs()
        [
            {
                "type" => "22f244eb-4925-49be-bce6-db58c2fb489a",
                "name" => "Label"
            },
            {
                "type" => "30991912-a9f2-426d-9b62-ec942c16c60a",
                "name" => "Curated Listing"
            },
            {
                "type" => "ea9f4f69-1c8c-49c9-b644-8854c1be75d8",
                "name" => "Date"
            },
            {
                "type" => "95c02a05-f289-4bf7-ac3a-4c76c2434f11",
                "name" => "Location"
            }
        ]
    end

    # NavigationPoints::interactivelySelectNavigationPointTypeXOrNull()
    def self.interactivelySelectNavigationPointTypeXOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("navigation point type: ", NavigationPoints::typeXs(), lambda{|item| item["name"] })
    end

    # ------------------------------------------------

    # NavigationPoints::toString(navpoint)
    def self.toString(navpoint)
        typename = NavigationPoints::typeXs().select{|typex| typex["type"] == navpoint["type"] }.map{|typex| typex["name"] }.first
        raise "b373b8d6-454e-4710-85e4-41160372395a" if typename.nil?
        "[navpoint: #{typename}] #{navpoint["description"]}"
    end

    # NavigationPoints::interactivelyIssueNewNavigationPointOrNull()
    def self.interactivelyIssueNewNavigationPointOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""

        typeX = NavigationPoints::interactivelySelectNavigationPointTypeXOrNull()
        return nil if typeX.nil?

        uuid = SecureRandom.uuid
        NavigationPoints::issueNewNavigationPoint(uuid, typeX["type"], description)
        NavigationPoints::getNavigationPointByUUIDOrNull(uuid)
    end

    # NavigationPoints::selectExistingNavigationPointOrNull()
    def self.selectExistingNavigationPointOrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(NavigationPoints::getNavigationPoints(), lambda{|navpoint| NavigationPoints::toString(navpoint)})
    end

    # NavigationPoints::selectNavigationPointByDescriptionOrNull(description)
    def self.selectNavigationPointByDescriptionOrNull(description)
        points = NavigationPoints::getNavigationPoints()
            .select{|navpoint| navpoint["description"].downcase == description.downcase }
        if points.empty? then
            return nil
        end
        if points.size == 1 then
            return points[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("navpoint", points, lambda{ |navpoint| NavigationPoints::toString(navpoint) })
    end

    # NavigationPoints::selectNavigationPointsByCloseDescription(description)
    def self.selectNavigationPointsByCloseDescription(description)
        NavigationPoints::getNavigationPoints()
            .map{|navpoint| 
                {
                    "navpoint" => navpoint,
                    "distance" => Utils::stringDistance2(navpoint["description"].downcase, description.downcase)
                }
            }
            .sort{|i1, i2| i1["distance"] <=> i2["distance"] }
            .first(5)
            .map{|item| item["navpoint"] }
            .sort{|np1, np2| np1["description"] <=> np2["description"] }
    end

    # NavigationPoints::architectureNavigationPointGivenDescriptionOrNull(description)
    def self.architectureNavigationPointGivenDescriptionOrNull(description)

        # Trying to extract it by exact description
        navpoint = NavigationPoints::selectNavigationPointByDescriptionOrNull(description)
        return navpoint if navpoint

        # Trying to extract it by approximate description
        navpoints = NavigationPoints::selectNavigationPointsByCloseDescription(description)
        if navpoints.size > 0 then
            navpoint = LucilleCore::selectEntityFromListOfEntitiesOrNull("navpoint", navpoints, lambda{|navpoint| NavigationPoints::toString(navpoint) })
            return navpoint if navpoint
        end

        # Making a new one
        typeX = NavigationPoints::interactivelySelectNavigationPointTypeXOrNull()
        return nil if typeX.nil?

        uuid = SecureRandom.uuid
        NavigationPoints::issueNewNavigationPoint(uuid, typeX["type"], description)
        NavigationPoints::getNavigationPointByUUIDOrNull(uuid)
    end

    # NavigationPoints::architectureNavigationPointOrNull()
    def self.architectureNavigationPointOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        NavigationPoints::architectureNavigationPointGivenDescriptionOrNull(description)
    end

    # ------------------------------------------------

    # NavigationPoints::landing(navpoint)
    def self.landing(navpoint)

        loop {

            return if NavigationPoints::getNavigationPointByUUIDOrNull(navpoint["uuid"]).nil? # could have been destroyed at the previous run

            navpoint = NavigationPoints::getNavigationPointByUUIDOrNull(navpoint["uuid"])

            system('clear')
            mx = LCoreMenuItemsNX1.new()
            
            puts NavigationPoints::toString(navpoint).green
            puts "uuid: #{navpoint["uuid"]}".yellow

            puts ""

            Network::getLinkedObjectsInTimeOrder(navpoint).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(navpoint["description"])
                return if description == ""
                NavigationPoints::updateNavigationPointDescription(navpoint["uuid"], description)
            })

            mx.item("link to architectured node".yellow, lambda {
                node = Patricia::achitectureNodeOrNull()
                return if node.nil?
                Network::linkObjects(navpoint, node)
            })

            mx.item("unlink".yellow, lambda {
                node = Network::selectOneOfTheLinkedNodeOrNull(navpoint)
                return if node.nil?
                Network::unlinkObjects(navpoint, node)
            })

            mx.item("architect ancestors path".yellow, lambda {
                Network::architectAncestorsPathsToNode(element)
            })

            mx.item("reshape: select connected items -> move to architectured navigation node".yellow, lambda {

                nodes, _ = LucilleCore::selectZeroOrMore("connected", [], Network::getLinkedObjectsInTimeOrder(navpoint), lambda{ |n| Patricia::toString(n) })
                return if nodes.empty?

                node2 = Patricia::achitectureNodeOrNull()
                return if node2.nil?

                return if nodes.any?{|node| node["uuid"] == node2["uuid"] }

                Network::reshape(navpoint, nodes, node2)
            })

            mx.item("view json object".yellow, lambda { 
                puts JSON.pretty_generate(navpoint)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NavigationPoints::destroy(navpoint)
                end
            })

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NavigationPoints::nyxSearchItems()
    def self.nyxSearchItems()
        NavigationPoints::getNavigationPoints()
            .map{|navpoint|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NavigationPoints::toString(navpoint)}",
                    "payload"  => navpoint
                }
            }
    end
end
