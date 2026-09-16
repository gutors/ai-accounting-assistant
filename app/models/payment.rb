class Payment < ApplicationRecord
  belongs_to :bank_statement
end
