# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

ActiveRecord::Base.transaction do
  puts "Seeding the database..."

  Faker::Config.locale = 'en-GB'

  FactoryBot.create_list(:organisation, 2).each do |organisation|
    FactoryBot.create_list(:user, 5, organisation: organisation).each do |user|
      contact_list = FactoryBot.create :contact_list

      FactoryBot.create :contact_list_user, contact_list: contact_list, user: user

      contacts = FactoryBot.create_list :contact, 50, contact_list: contact_list

      need_categories = ['groceries and cooked meals', 'physical and mental wellbeing', 'financial support',
                        'staying Social', 'prescription pickups', 'book drops and entertainment', 'dog walking', 'other']

      contacts.first(10).each do |contact|
        [1, 2, 3].sample.times do
          FactoryBot.create :need,
                            contact: contact,
                            user: user,
                            category: need_categories.sample,
                            completed_on: [nil, [1,2,3].sample.days.ago].sample
        end
      end
    end
  end

  puts "Finished seeding the database."
end

# make an initial user for sake of the readme
User.create(
  email: "admin@example.com",
  first_name: "Example",
  last_name: "User",
  admin: true,
  invited: "2020-03-25 00:00:00"
)