# frozen_string_literal: true

class ImportedItem < ApplicationRecord
  include Filterable

  require 'roo'

  validates_uniqueness_of :name
  validates :name, presence: true, allow_blank: true
  has_many :contacts
  has_many :rejected_contacts
  attr_reader :file
  belongs_to :user, optional: true

  def file=(file)
    @file = file
    self.name = file.original_filename
  end

  def import
    contacts_rows = []
    Roo::Spreadsheet.open(file.path).each_with_index do |row, idx|
      next if idx.zero?

      contacts_rows << row
    end

    @unique_contacts, @not_unique_contacts = unique_and_non_unique_records contacts_rows

    ImportedItem.transaction do
      save!
      process_unique_contacts(@unique_contacts)
      process_non_unique_contacts(@not_unique_contacts)

      self.imported = @unique_contacts.size
      self.rejected = @not_unique_contacts.size
      save!
    end
  end

  private

  def process_unique_contacts(unique_contacts)
    contacts = []
    unique_contacts.each do |row|
      contacts << Contact.new(
        test_and_trace_account_id: row[0],
        nhs_number: row[1],
        is_vulnerable: (row[2] == 1 || row[2].to_s.downcase == 'true'),
        first_name: row[3],
        surname: row[4],
        date_of_birth: row[5],
        email: row[6],
        mobile: row[7],
        telephone: row[8],
        address: row[9],
        postcode: row[10],
        needs: [Need.new(category: 'Outbound', start_on: Date.today, name: row[11])],
        test_trace_creation_date: row[12],
        isolation_start_date: row[13],
        imported_item: self
      )
    end
    Contact.import! contacts, recursive: true, all_or_none: true
  end

  def process_non_unique_contacts(not_unique_contacts)
    rejected_contacts = []
    not_unique_contacts.each do |row|
      rejected_contacts << RejectedContact.new(
        test_and_trace_account_id: row[0],
        nhs_number: row[1],
        is_vulnerable: (row[2] == 1 || row[2].to_s.downcase == 'true'),
        first_name: row[3],
        surname: row[4],
        date_of_birth: row[5],
        email: row[6],
        mobile: row[7],
        telephone: row[8],
        address: row[9],
        postcode: row[10],
        needs: row[11],
        test_trace_creation_date: row[12],
        isolation_start_date: row[13],
        imported_item: self,
        reason: row[14].nil? ? 'unspecified' : row[14]
      )
    end

    RejectedContact.import! rejected_contacts, recursive: true, all_or_none: true
  end

  def unique_and_non_unique_records(rows)
    not_unique_records = []
    unique_records = []
    rows.each do |row|
      if check_row(row)
        not_unique_records << row
      else
        unique_records << row
      end
    end
    [unique_records, not_unique_records]
  end

  def check_row(row)
    if not_empty(row[0]) && not_zero(Contact.where('test_and_trace_account_id = ?', row[0].to_s))
      row << "Test and Trace Account ID - Duplicate [#{row[0]}]"
    elsif not_empty(row[1]) && not_zero(Contact.where('nhs_number = ?', row[1].to_s))
      row << "NHS Number - Duplicate [#{row[1]}]"
    elsif not_empty_name_and_dob(row)
      row << "Name & DOB - Duplicate [#{row[3].downcase}, #{row[4].downcase}, #{row[5]}]"
    end
  end

  def not_empty(col)
    !col.nil? && !col.to_s.strip.empty?
  end

  def not_zero(records)
    !records.count.zero?
  end

  def not_empty_name_and_dob(row)
    not_empty(row[3]) && not_empty(row[4]) && not_empty(row[5]) &&
      not_zero(
        Contact.where('lower(first_name) = lower(?) and lower(surname) = lower(?) and date_of_birth = (?)', row[3], row[4], Date.parse(row[5].to_s))
      )
  end
end
