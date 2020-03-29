class Contact < ApplicationRecord
  has_paper_trail

  belongs_to :contact_list, optional: true
  has_many :notes, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :uncompleted_tasks, -> { uncompleted }, class_name: 'Task'
  has_many :completed_tasks, -> { completed }, class_name: 'Task'

  acts_as_ordered_taggable

  validates :first_name, presence: true

  enum priority: { low: 'low', medium: 'medium', high: 'high' }, _suffix: true

  def name
    [first_name, surname].join(' ')
  end
end
