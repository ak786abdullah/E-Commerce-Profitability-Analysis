from sqlalchemy import create_engine
from dotenv import load_dotenv
import pandas as pd
import os

load_dotenv()


db_password = os.getenv("DB_PASSWORD")

connection_string = (
    f"mysql+pymysql://root:{db_password}@localhost/e_commerce_profitability_analysis"
)

engine = create_engine(connection_string)

tables = {
    "marketing_spend": marketing_spend,
    "orders": order_data,
    "products": product_data
}

for table_name, df in tables.items():
    df.to_sql(
        name=table_name,
        con=engine,
        if_exists="replace",   # use "append" if table already exists
        index=False
    )

print(" All tables imported successfully!")


