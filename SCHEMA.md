# Fintech BI Project — Database Schema

## fact_transactions
| Column | Type | Description |
|--------|------|-------------|
| transaction_id | INT | Primary key |
| customer_key | INT | FK to dim_customer |
| card_key | INT | FK to dim_card |
| merchant_key | INT | FK to dim_merchant |
| bank_key | INT | FK to dim_bank |
| scheme_key | INT | FK to dim_scheme |
| date_key | INT | FK to dim_date |
| transaction_amount | DECIMAL | Amount spent by customer |
| interchange_fee | DECIMAL | Fee earned by Paynetics |
| scheme_fee | DECIMAL | Fee paid to Visa/Mastercard |
| fx_rate | DECIMAL | Exchange rate if cross-currency |
| fraud_loss | DECIMAL | Amount lost to fraud |
| is_chargeback | BOOLEAN | Whether transaction was disputed |

## dim_customer
| Column | Type | Description |
|--------|------|-------------|
| customer_key | INT | Primary key |
| first_name | VARCHAR | Customer first name |
| last_name | VARCHAR | Customer last name |
| email | VARCHAR | Contact email |
| telephone | VARCHAR | Contact number |
| city | VARCHAR | Customer city |
| country | VARCHAR | Customer country |
| is_blocked | BOOLEAN | Whether customer is blocked |
| block_reason | VARCHAR | Reason for block if applicable |

## dim_card
| Column | Type | Description |
|--------|------|-------------|
| card_key | INT | Primary key |
| card_type | VARCHAR | Normal or premium |
| card_network | VARCHAR | Visa or Mastercard |
| currency | VARCHAR | BGN, EUR, USD |
| card_status | VARCHAR | Active, frozen, cancelled, expired |
| date_issued | DATE | When card was issued |
| expiry_date | DATE | When card expires |
| customer_key | INT | FK to dim_customer |

## dim_merchant
| Column | Type | Description |
|--------|------|-------------|
| merchant_key | INT | Primary key |
| merchant_name | VARCHAR | Name of merchant |
| business_category | VARCHAR | Fast food, retail, etc |
| city | VARCHAR | Merchant city |
| country | VARCHAR | Merchant country |
| bank_key | INT | FK to dim_bank |

## dim_bank
| Column | Type | Description |
|--------|------|-------------|
| bank_key | INT | Primary key |
| bank_name | VARCHAR | Name of bank |
| country | VARCHAR | Country of bank |
| bank_type | VARCHAR | Issuer, acquirer, or both |

## dim_scheme
| Column | Type | Description |
|--------|------|-------------|
| scheme_key | INT | Primary key |
| scheme_name | VARCHAR | Visa, Mastercard, Amex |
| region | VARCHAR | Europe, Global, etc |
| interchange_rate | DECIMAL | Rate set by scheme |

## dim_date
| Column | Type | Description |
|--------|------|-------------|
| date_key | INT | Primary key |
| date | DATE | Full date |
| day | INT | Day number |
| month | INT | Month number |
| quarter | INT | Quarter number |
| year | INT | Year number |
| is_weekend | BOOLEAN | Whether date is weekend |