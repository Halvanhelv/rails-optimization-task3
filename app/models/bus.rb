# frozen_string_literal: true

class Bus < ApplicationRecord
  MODELS = %w[
    Ikarus
    Mercedes
    Scania
    Bukhanka
    UAZ
    Sprinter
    GAZ
    PAZ
    Volvo
    Gazelle
  ].freeze

  has_many :trips
  has_and_belongs_to_many :services, join_table: :buses_services

  validates :number, presence: true, uniqueness: true
  validates :model, inclusion: { in: MODELS }
end
