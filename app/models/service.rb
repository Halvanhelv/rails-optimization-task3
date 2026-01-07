# frozen_string_literal: true

class Service < ApplicationRecord
  SERVICES = [
    'WiFi',
    'Toilet',
    'Working toilet',
    'Seat belts',
    'Shared air conditioning',
    'Individual air conditioning',
    'Shared TV',
    'Individual TV',
    'Stewardess',
    'No need to print ticket'
  ].freeze

  has_and_belongs_to_many :buses, join_table: :buses_services

  validates :name, presence: true
  validates :name, inclusion: { in: SERVICES }
end
