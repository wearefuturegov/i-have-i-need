Given('a resident with a {string} need') do |need|
  @contact = Contact.create!(first_name: 'Test')
  step "I add needs \"#{need}\""
  step 'I submit the add needs form'
end

Given('a resident with {string} needs') do |needs|
  @contact = Contact.create!(first_name: 'Test')
  needs.split(', ').each do |need|
    step "I add needs \"#{need}\""
    step 'I submit the add needs form'
  end
end

When('I add a {string} note {string}') do |category, content|
  visit "/needs/#{@contact.needs.first.id}"
  choose_note_type_from(category)
  fill_in('note_body', with: content)
end

And(/^I submit the form to create the note$/) do
  click_button('Add update')
end

Then('the list of notes contains {string}') do |content|
  expect(page).to have_content(content)
end

And('the note category is {string}') do |category|
  expect(page).to have_content(category)
end

def choose_note_type_from(category)
  note_types = { 'Successful Call': 'category_phone_success',
                 'Left Message': 'category_phone_message',
                 'Failed Call': 'category_phone_failure',
                 'Note': 'category_general' }
  radio_id = note_types.fetch(category.to_sym)
  page.find("label[for=#{radio_id}]").click
end
