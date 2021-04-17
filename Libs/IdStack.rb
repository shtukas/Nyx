
# encoding: UTF-8

class IdStack

    # IdStack::getIds()
    def self.getIds()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "4c7bb2b3-9f5a-4acb-8e05-ead7deffebc9", "[]"))
    end

    # IdStack::stack(id)
    def self.stack(id)
        ids = IdStack::getIds()
        ids = [id] + ids
        KeyValueStore::set(nil, "4c7bb2b3-9f5a-4acb-8e05-ead7deffebc9", JSON.generate(ids))
    end

    # IdStack::unStackOrNull()
    def self.unStackOrNull()
        ids = IdStack::getIds()
        return nil if ids.nil?
        id = ids.shift
        KeyValueStore::set(nil, "4c7bb2b3-9f5a-4acb-8e05-ead7deffebc9", JSON.generate(ids))
        id
    end
end
