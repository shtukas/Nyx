
# encoding: UTF-8

class ListingEntityMapping

    # ListingEntityMapping::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/listing-entity-mapping.sqlite3"
    end

    # ListingEntityMapping::add(listinguuid, entryuuid)
    def self.add(listinguuid, entryuuid)
        db = SQLite3::Database.new(ListingEntityMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _mapping_ where _listinguuid_=? and _entityuuid_=?", [listinguuid, entryuuid]
        db.execute "insert into _mapping_ (_listinguuid_, _entityuuid_) values (?,?)", [listinguuid, entryuuid]
        db.close
    end

    # ListingEntityMapping::remove(listinguuid, entryuuid)
    def self.remove(listinguuid, entryuuid)
        db = SQLite3::Database.new(ListingEntityMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _mapping_ where _listinguuid_=? and _entityuuid_=?", [listinguuid, entryuuid]
        db.close
    end

    # ListingEntityMapping::entities(listinguuid): Array[NxEntities]
    def self.entities(listinguuid)
        db = SQLite3::Database.new(ListingEntityMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _mapping_ where _listinguuid_=?" , [listinguuid] ) do |row|
            answer << row["_entityuuid_"]
        end
        db.close
        answer.uniq.map{|uuid| NxEntities::getEntityByIdOrNull(uuid) }.compact
    end

    # ListingEntityMapping::listings(entityuuid): Array[NxListings]
    def self.listings(entityuuid)
        db = SQLite3::Database.new(ListingEntityMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _mapping_ where _entityuuid_=?" , [entityuuid] ) do |row|
            answer << row["_listinguuid_"]
        end
        db.close
        answer.uniq.map{|uuid| NxListings::getListingByIdOrNull(uuid) }.compact
    end
end
