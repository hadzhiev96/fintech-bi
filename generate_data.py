import psycopg2
from faker import Faker
import random
from datetime import date, timedelta

fake = Faker()

conn = psycopg2.connect(
    host="localhost", port=5432, database="fintech", user="analyst", password="admin123"
)

cursor = conn.cursor()


def create_tables():
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dim_date (
            date_key SERIAL PRIMARY KEY,
            date DATE NOT NULL,
            day INT NOT NULL,
            month INT NOT NULL,
            quarter INT NOT NULL,
            year INT NOT NULL,
            is_weekend BOOLEAN NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dim_bank (
            bank_key SERIAL PRIMARY KEY,
            bank_name VARCHAR(100) NOT NULL,
            country VARCHAR(100) NOT NULL,
            bank_type VARCHAR(50) NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dim_customer (
            customer_key SERIAL PRIMARY KEY,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL,
            telephone VARCHAR(50) NOT NULL,
            city VARCHAR(100) NOT NULL,
            country VARCHAR(100) NOT NULL,
            is_blocked BOOLEAN NOT NULL,
            block_reason VARCHAR(200)
        );
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dim_scheme (
            scheme_key SERIAL PRIMARY KEY,
            scheme_name VARCHAR(50) NOT NULL,
            region VARCHAR(50) NOT NULL,
            interchange_rate DECIMAL(5,4) NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dim_merchant (
            merchant_key SERIAL PRIMARY KEY,
            merchant_name VARCHAR(200) NOT NULL,
            business_category VARCHAR(100) NOT NULL,
            city VARCHAR(100) NOT NULL,
            country VARCHAR(100) NOT NULL,
            bank_key INT REFERENCES dim_bank(bank_key)
        );
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dim_card (
            card_key SERIAL PRIMARY KEY,
            card_type VARCHAR(50) NOT NULL,
            card_network VARCHAR(50) NOT NULL,
            currency VARCHAR(10) NOT NULL,
            card_status VARCHAR(50) NOT NULL,
            date_issued DATE NOT NULL,
            expiry_date DATE NOT NULL,
            customer_key INT REFERENCES dim_customer(customer_key)
        );
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS fact_transactions (
            transaction_id SERIAL PRIMARY KEY,
            customer_key INT REFERENCES dim_customer(customer_key),
            card_key INT REFERENCES dim_card(card_key),
            merchant_key INT REFERENCES dim_merchant(merchant_key),
            bank_key INT REFERENCES dim_bank(bank_key),
            scheme_key INT REFERENCES dim_scheme(scheme_key),
            date_key INT REFERENCES dim_date(date_key),
            transaction_amount DECIMAL(10,2) NOT NULL,
            interchange_fee DECIMAL(10,2) NOT NULL,
            scheme_fee DECIMAL(10,2) NOT NULL,
            fx_rate DECIMAL(10,4) NOT NULL,
            fraud_loss DECIMAL(10,2) NOT NULL,
            is_chargeback BOOLEAN NOT NULL
        );
    """)

    conn.commit()
    print("Tables created successfully!")


def generate_dim_date(start_date, end_date):
    """Generate date dimension from start_date to end_date."""
    cursor.execute("TRUNCATE TABLE dim_date CASCADE;")
    current_date = start_date
    while current_date <= end_date:
        cursor.execute(
            """INSERT INTO dim_date
                       (date,day,month,quarter,year,is_weekend)
                       VALUES (%s,%s,%s,%s,%s,%s)
                       """,
            (
                current_date,
                current_date.day,
                current_date.month,
                (current_date.month - 1) // 3 + 1,
                current_date.year,
                current_date.weekday() >= 5,
            ),
        )
        current_date += timedelta(days=1)
    conn.commit()
    print("dim_date populated")


def generate_dim_bank(n=20):
    """Generate n synthetic banks."""
    cursor.execute("""TRUNCATE TABLE dim_bank CASCADE;""")
    bank_types = ["issuer", "acquirer", "both"]
    countries = ["Bulgaria", "Germany", "France", "Netherlands", "Italy", "Spain"]

    for _ in range(n):
        cursor.execute(
            """INSERT INTO dim_bank (bank_name, country, bank_type) VALUES(%s,%s,%s)""",
            (
                fake.company() + " Bank",
                random.choice(countries),
                random.choice(bank_types),
            ),
        )
    conn.commit()
    print("dim_bank populated!")


def generate_dim_customer(n=500):
    """Genrating n synthetic customers."""
    cursor.execute("""TRUNCATE TABLE dim_customer CASCADE;""")
    block_reasons = ["fraud", "AML flag", "KYC failure", None]
    for _ in range(n):
        is_blocked = random.random() < 0.05
        cursor.execute(
            """INSERT INTO dim_customer 
            (first_name, last_name, email, telephone,
              city, country, is_blocked, block_reason) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                       """,
            (
                fake.first_name(),
                fake.last_name(),
                fake.email(),
                fake.phone_number(),
                fake.city(),
                fake.country(),
                is_blocked,
                random.choice(block_reasons) if is_blocked else None,
            ),
        )
    conn.commit()
    print("dim_customer populated!")


def generate_dim_scheme():
    """Generate payment schemes."""
    cursor.execute("""TRUNCATE TABLE dim_scheme CASCADE;""")
    schemes = [
        ("Visa", "Europe", 0.0200),
        ("Mastercard", "Europe", 0.0210),
        ("Visa", "Global", 0.0180),
        ("Mastercard", "Global", 0.0190),
        ("Amex", "Global", 0.0250),
    ]
    for scheme in schemes:
        cursor.execute(
            """
            INSERT INTO dim_scheme 
                (scheme_name, region, interchange_rate)
            VALUES (%s, %s, %s)
        """,
            scheme,
        )
    conn.commit()
    print("dim_scheme populated!")


def generate_dim_merchant(n=100):
    """Generate n synthetic merchants"""
    cursor.execute("""TRUNCATE TABLE dim_merchant CASCADE;""")

    cursor.execute("""SELECT bank_key FROM dim_bank;""")
    bank_keys = [row[0] for row in cursor.fetchall()]

    categories = [
        "Fast Food",
        "Retail",
        "Grocery",
        "Travel",
        "Entertainment",
        "healthcare",
        "Fuel",
        "Online",
    ]

    countries = ["Bulgaria", "Germany", "France", "Netherlands", "Italy", "Spain"]

    for _ in range(n):
        cursor.execute(
            """INSERT INTO dim_merchant 
                (merchant_name, business_category, city, country, bank_key)
               VALUES (%s, %s, %s, %s, %s)
            """,
            (
                fake.company(),
                random.choice(categories),
                fake.city(),
                random.choice(countries),
                random.choice(bank_keys),
            ),
        )
    conn.commit()
    print("dim_merchant populated!")


def generate_dim_card(n=700):
    """Generate n synthetic cards."""
    cursor.execute("""TRUNCATE TABLE dim_card CASCADE;""")

    cursor.execute("""SELECT customer_key FROM dim_customer;""")
    customer_keys = [row[0] for row in cursor.fetchall()]

    card_types = ["normal", "premium"]
    card_networks = ["Visa", "Mastercard"]
    currencies = ["BGN", "EUR", "USD"]
    card_statuses = ["active", "frozen", "cancelled", "expired"]

    for _ in range(n):
        date_issued = fake.date_between(
            start_date=date(2020, 1, 1), end_date=date(2024, 1, 1)
        )
        expiry_date = date(date_issued.year + 3, date_issued.month, date_issued.day)
        cursor.execute(
            """INSERT INTO dim_card
                (card_type, card_network, currency, card_status,
                 date_issued, expiry_date, customer_key)
               VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                random.choice(card_types),
                random.choice(card_networks),
                random.choice(currencies),
                random.choice(card_statuses),
                date_issued,
                expiry_date,
                random.choice(customer_keys),
            ),
        )
    conn.commit()
    print("dim_card populated!")


def generate_fact_transactions(n=50000):
    """Generate n synthetic transactions."""
    cursor.execute("TRUNCATE TABLE fact_transactions CASCADE;")

    cursor.execute("SELECT customer_key FROM dim_customer;")
    customer_keys = [row[0] for row in cursor.fetchall()]

    cursor.execute("SELECT card_key FROM dim_card;")
    card_keys = [row[0] for row in cursor.fetchall()]

    cursor.execute("SELECT merchant_key FROM dim_merchant;")
    merchant_keys = [row[0] for row in cursor.fetchall()]

    cursor.execute("SELECT bank_key FROM dim_bank;")
    bank_keys = [row[0] for row in cursor.fetchall()]

    cursor.execute("SELECT scheme_key, interchange_rate FROM dim_scheme;")
    schemes = cursor.fetchall()

    cursor.execute("SELECT date_key FROM dim_date;")
    date_keys = [row[0] for row in cursor.fetchall()]

    for _ in range(n):
        amount = round(random.uniform(5.00, 5000.00), 2)
        scheme = random.choice(schemes)
        scheme_key = scheme[0]
        interchange_rate = scheme[1]

        interchange_fee = round(float(amount) * float(interchange_rate), 2)
        scheme_fee = round(float(amount) * 0.003, 2)

        is_fraud = random.random() < 0.02
        fraud_loss = (
            round(float(amount) * random.uniform(0.5, 1.0), 2) if is_fraud else 0.00
        )

        is_chargeback = is_fraud and random.random() < 0.60

        fx_rate = (
            round(random.uniform(0.95, 1.85), 4) if random.random() < 0.30 else 1.0000
        )

        cursor.execute(
            """INSERT INTO fact_transactions
                (customer_key, card_key, merchant_key, bank_key,
                 scheme_key, date_key, transaction_amount,
                 interchange_fee, scheme_fee, fx_rate,
                 fraud_loss, is_chargeback)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                random.choice(customer_keys),
                random.choice(card_keys),
                random.choice(merchant_keys),
                random.choice(bank_keys),
                scheme_key,
                random.choice(date_keys),
                amount,
                interchange_fee,
                scheme_fee,
                fx_rate,
                fraud_loss,
                is_chargeback,
            ),
        )

    conn.commit()
    print("fact_transactions populated!")


cursor.execute("DROP TABLE IF EXISTS fact_transactions;")
cursor.execute("DROP TABLE IF EXISTS dim_card;")
cursor.execute("DROP TABLE IF EXISTS dim_merchant;")
cursor.execute("DROP TABLE IF EXISTS dim_customer;")
cursor.execute("DROP TABLE IF EXISTS dim_scheme;")
cursor.execute("DROP TABLE IF EXISTS dim_bank;")
cursor.execute("DROP TABLE IF EXISTS dim_date;")

create_tables()
generate_dim_date(date(2023, 1, 1), date(2024, 12, 31))
generate_dim_bank()
generate_dim_customer()
generate_dim_scheme()
generate_dim_merchant()
generate_dim_card()
generate_fact_transactions()
