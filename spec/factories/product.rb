FactoryBot.define do
  sequence(:title) { |n| "product #{n}" }
# factory for product model with minimum required fields
  factory :product do
    title
    vendor  "amazon"
    product_type "book"
  end
end
