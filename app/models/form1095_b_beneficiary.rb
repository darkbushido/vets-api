class Form1095BBeneficiary < ApplicationRecord
  belongs_to :form1095_b #, inverse_of: form1095_b_beneficiaries

  validates :last_name, presence: true
  validates :ssn, presence: true, unless: -> {birth_date.present?}, format: /\A\d{9}\z/
  validates :birth_date, presence: true, unless: -> {ssn.present?}


end
