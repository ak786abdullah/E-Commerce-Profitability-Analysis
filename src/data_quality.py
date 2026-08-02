import pandas as pd
import matplotlib.pyplot as plt

# create a function to check three key data quality issues: data types, duplicates, missing values
def check_data_quality(data):
    # check data types
    print(data.info())
    
    # Check for duplicate rows
    print(f"Duplicate rows in data:{data.duplicated().sum()}")
    
    # Check for missing values
    print(f"Missing values in data:\n{data.isnull().sum()}") 

# create a function to check for outliers by using boxplots for numerical columns
def check_outliers(data, column):
    plt.boxplot(data[column])
    plt.title(f'Boxplot of {column}')
    plt.ylabel(column)
    plt.show()

# create a function to show outliers in the  column
def show_outliers_iqr(df, column):
    Q1 = df[column].quantile(0.25)
    Q3 = df[column].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    return df[(df[column] < lower_bound) | (df[column] > upper_bound)].sort_values(by=column, ascending=False) 


# create a function to check data consistancy in catgorical column
def check_data_consistency(data, column):
    value_counts = data[column].value_counts()
    print(f"Value counts in {column}:\n{value_counts}")
