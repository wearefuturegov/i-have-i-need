# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NeedsCreator do
  before(:each) do
    @builder = double(ActiveRecord::Associations::CollectionProxy)
    allow(@builder).to receive_messages(build: @builder, save: @builder)

    @test_contact = double('Contact')
    allow(@test_contact).to receive(:id).and_return 1
    allow(@test_contact).to receive(:name).and_return 'Contact name'
    allow(@test_contact).to receive(:needs).and_return @builder
  end

  it 'saves each active need' do
    # three needs, first two active
    needs_list = {
      '1' => { 'active' => 'true', 'name' => 'category1' },
      '2' => { 'active' => 'true', 'name' => 'category2' },
      '3' => { 'active' => 'false', 'name' => 'category3' }
    }
    expect(@builder).to receive(:save).twice
    described_class.create_needs(@test_contact, needs_list, nil)
  end

  it 'sets a default description if none is provided' do
    needs_list = { '1' => { 'active' => 'true', 'name' => 'category' } }

    expect(@builder).to receive(:build).with(hash_including(name: 'Contact name needs category')).once
    described_class.create_needs(@test_contact, needs_list, nil)
  end

  it 'sets the description from the provided description if provided' do
    needs_list = { '1' => { 'active' => 'true', 'name' => 'category', 'description' => 'test description' } }

    expect(@builder).to receive(:build).with(hash_including(name: 'test description')).once
    described_class.create_needs(@test_contact, needs_list, nil)
  end

  it "adds an 'other' need if a description is provided" do
    needs_list = { 1 => { active: false } }

    expect(@builder).to receive(:build).with(hash_including(name: 'test other description')).once
    described_class.create_needs(@test_contact, needs_list, 'test other description')
  end
end
