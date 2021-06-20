
# encoding: UTF-8

=begin
The master copy of this class is in Catalyst.
The copy in Nyx is not exactly the same as the name of Elizabeth is not the same.
=end

class Nx102

    # Nx102::interactivelyIssueNewCoordinates3OrNull(): nil or coordinates = [contentType, payload]
    def self.interactivelyIssueNewCoordinates3OrNull()

        contentType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])

        if contentType.nil? then
            return nil
        end  

        if contentType == "Line" then
            payload = ""
        end

        if contentType == "Url" then
            input = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            if input == "" then
                return nil
            end
            payload = input
        end

        if contentType == "Text" then
            text = Utils::editTextSynchronously("")
            payload = BinaryBlobsService::putBlob(text)
        end

        if contentType == "ClickableType" then
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if !File.exists?(f1) or !File.file?(f1) then
                return nil
            end
            nhash = BinaryBlobsService::putBlob(IO.read(f1))
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
        end

        if contentType == "AionPoint" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if !File.exists?(location) then
                return nil
            end
            payload = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
        end

        [contentType, payload]
    end

    # Nx102::access(contentType, payload): nil or coordinates = [contentType, payload]
    def self.access(contentType, payload)

        if contentType == "Line" then
            return nil
        end
        if contentType == "Url" then
            puts "opening '#{payload}'"
            Utils::openUrlUsingSafari(payload)
            return nil
        end
        if contentType == "Text" then
            puts "opening text '#{payload}' (edit mode)"
            nhash = payload
            text1 = BinaryBlobsService::getBlobOrNull(nhash)
            text2 = Utils::editTextSynchronously(text1)
            if (text1 != text2) and LucilleCore::askQuestionAnswerAsBoolean("commit changes ? ") then
                payload = BinaryBlobsService::putBlob(text2)
                return [contentType, payload]
            end
            return nil
        end
        if contentType == "ClickableType" then
            puts "opening file '#{payload}'"
            nhash, extension = payload.split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            if File.exists?(filepath) then
                puts "Cannot export [#{contentType}, #{payload}] at '#{filepath}' because file is already on Desktop"
                LucilleCore::pressEnterToContinue()
                return nil
            end
            blob = BinaryBlobsService::getBlobOrNull(nhash)
            File.open(filepath, "w"){|f| f.write(blob) }
            puts "I have exported the file at '#{filepath}'"
            system("open '#{filepath}'")
            return nil
        end
        if contentType == "AionPoint" then
            puts "opening aion point '#{payload}'"
            nhash = payload
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            object = AionCore::getAionObjectByHash(Elizabeth.new(), nhash)
            location = "#{targetReconstructionFolderpath}/#{object["name"]}"
            if File.exists?(location) then
                puts "Cannot export [#{contentType}, #{payload}] at '#{location}' because file is already on Desktop"
                LucilleCore::pressEnterToContinue()
                return nil
            end
            AionCore::exportHashAtFolder(Elizabeth.new(), nhash, targetReconstructionFolderpath)
            puts "Export completed"
            return nil
        end
        raise "[error: c803322d-298c-4c61-aef3-4e36743cf360]"
    end

    # Nx102::postAccessCleanUp(contentType, payload)
    def self.postAccessCleanUp(contentType, payload)

        if contentType == "Line" then
            return
        end
        if contentType == "Url" then
            return
        end
        if contentType == "Text" then
            return
        end
        if contentType == "ClickableType" then
            puts "cleaning file '#{payload}'"
            nhash, extension = payload.split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            return if !File.exists?(filepath)
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end
        if contentType == "AionPoint" then
            puts "cleaning aion point '#{payload}'"
            nhash = payload
            aionObject = AionCore::getAionObjectByHash(Elizabeth.new(), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"
            return if !File.exists?(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end
        raise "[error: f3394206-b2de-45e8-a18d-bbd7610f9ad9]"
    end

    # Nx102::edit(contentType, payload): nil or coordinates = [contentType, payload]
    def self.edit(contentType, payload)

        if contentType == "Line" then
            # Line does not carry data per se, the content is the description 
            return
        end
        if contentType == "Url" then  
            input = LucilleCore::askQuestionAnswerAsString("url (empty for not changing): ")
            if input != "" then
                payload = input
            end
            return [contentType, payload]
        end
        if contentType == "Text" then
            nhash = payload
            text1 = BinaryBlobsService::getBlobOrNull(nhash)
            text2 = Utils::editTextSynchronously(text1)
            payload = BinaryBlobsService::putBlob(text2)
            return [contentType, payload]
        end
        if contentType == "ClickableType" then 
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if File.exists?(f1) then
                nhash = BinaryBlobsService::putBlob(IO.read(f1)) # bad choice, this file could be large
                dottedExtension = File.extname(filenameOnTheDesktop)
                payload = "#{nhash}|#{dottedExtension}"
                return [contentType, payload]
            else
                puts "Could not find file: #{f1}"
                LucilleCore::pressEnterToContinue()
                return nil
            end
            return nil
        end
        if contentType == "AionPoint" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop) (empty to abort): ")
            if locationNameOnTheDesktop.size > 0 then
                location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
                if File.exists?(location) then
                    payload = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
                    return [contentType, payload]
                else
                    puts "Could not find file: #{filepath}"
                    LucilleCore::pressEnterToContinue()
                    return nil
                end
            end
            return nil
        end
        raise "[error: 8f50078a-e5aa-4cce-8c82-04cef8518939]"
    end

    # Nx102::transmute(contentType, payload)
    def self.transmute(contentType, payload)
        puts "Nx102::transmute is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end
