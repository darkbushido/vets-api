FactoryBot.define do
  factory :form1095_b do
    first_name { "First" }
    middle_name { "Middle" }
    last_name { "Last" }
    birth_date { "2000-02-16" }
    ssn { "6363663" }
    address { "123 Test St" }
    city { "Fake City" }
    state { "California" }
    country { "USA" }
    zip_code { "12334" }
    # province { "MyString" }
    # foreign_zip { "MyString" }
    coverage_months { [true, false, false, false, false, false, false, false, false, false, false, false, false] }
    tax_year { 2021 }
    is_beneficiary { false }
    veteran_icn { "3456787654324567" }
  end
end
