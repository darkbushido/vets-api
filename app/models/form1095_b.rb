class Form1095B < ApplicationRecord
  # belongs_to :account # ...?

  has_many :form1095_b_beneficiaries

  # validations for required form fields
  validates :veteran_icn, :last_name, :address, :tax_year, presence: true
  validates :ssn, presence: true, unless: -> { birth_date.present? }, format: /\A\d{9}\z|\A\d{4}\z/
  validates :birth_date, presence: true, unless: -> { ssn.present? }
  validates :coverage_months, length: { is: 13 }
  validates :zip_code, presence: true, format: /\A\d{5}\z|\A\d{5}-\d{4}\z/
  validates :veteran_icn, uniqueness: { scope: :tax_year}
  # more validations

  # scopes
  scope :find_by_icn_and_year, -> (icn, year) {where("veteran_icn = ? and tax_year = ?", icn, year).first}

  # assumes ssn is already last 4 if only 4 digits are provided
  before_save :store_last_4, if: -> { ssn.size == 9 }

  # calls pdf generator function
  def get_pdf
    puts 'Generating PDF!' # placeholder
    # gen_1095B(self)
    generate_pdf
  end


  private

  def generate_pdf
    "Here is PDF!"
  end

  def store_last_4
    self.ssn = self.ssn[-4...]
  end
end
