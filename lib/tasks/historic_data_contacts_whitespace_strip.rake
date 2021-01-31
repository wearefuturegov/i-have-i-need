namespace :strip_whitespace do
  desc 'Strip whitespace from specified historic Contact entrys (one off task)'
  task data_cleanup: :environment do
    BATCH_SIZE = 1000
    # Process in batches set by the batch size 1000 is default.
    targeted_attributes = ['first_name', 'middle_names', 'surname']
    where_statement = []
    updated_contacts = []

    # These are the fields/attributes of Contact that to 'clean'
    targeted_attributes.each do |field|
      where_statement << "LENGTH(RTRIM(LTRIM(#{field}))) <> LENGTH(#{field})"
    end

    Contact.where(where_statement.join(' OR ')).find_in_batches(batch_size: BATCH_SIZE) do |contacts|
      temp_updated_contacts = []

      contacts.each do |contact|
        contact.save!(touch: false)
        temp_updated_contacts << contact.id
      rescue ActiveRecord::RecordInvalid
        puts "Records updated - incomplete (#{temp_updated_contacts.size} of #{BATCH_SIZE}):\n#{temp_updated_contacts}"
        raise ActiveRecord::RecordInvalid
      end
      puts "Records updated (#{BATCH_SIZE}):\n#{temp_updated_contacts}"
      updated_contacts << temp_updated_contacts
    end
    puts 'Completed'
  end
end
