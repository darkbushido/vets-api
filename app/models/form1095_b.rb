class Form1095B < ApplicationRecord
  # belongs_to :account # ...?

  has_many :form1095_b_beneficiaries

  # validations for required form fields
  validates :veteran_icn, :last_name, :address, presence: true
  validates :ssn, presence: true, unless: -> { birth_date.present? }, format: /\A\d{9}\z|\A\d{4}\z/
  validates :birth_date, presence: true, unless: -> { ssn.present? }
  validates :coverage_months, length: { is: 13 }
  validates :zip_code, presence: true, format: /\A\d{5}\z|\A\d{5}-\d{4}\z/

  # assumes ssn is already last 4 if only 4 digits are provided
  before_save :update_modified_date, if: -> { ssn.size == 9 }

  # calls pdf generation function
  def gen_pdf
    return nil unless self.isVeteran?

    'Generating PDF!' # placeholder
    # gen_1095B(self)
  end


  private

  def update_modified_date
    self.last_modified = DateTime.now
  end

  def store_last_4
    self.ssn = self.ssn[-4...]
  end
end
