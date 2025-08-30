import pandas as pd

# ========================================================
# Validation Functions
# ========================================================

# Using vectorized operations for optimisation (Columnar Validation)
def validate_dataset(df, validation_rules: dict, error_log):
    """
    Validates the dataset based on the provided validation rules and logs any validation errors.

    Args:
        df (pandas.DataFrame): The dataset to validate.
        validation_rules (dict): A dictionary containing the validation rules for each column in the dataset.
        error_log (StringIO): A file-like object to log error messages.

    Returns:
        tuple: A tuple containing the cleaned DataFrame (with invalid rows dropped) and the error log.
    """
    # Set empty list to capture error rows
    invalid_rows = []
    # Focus on data_validation key in the data configuration json
    validation_rules = validation_rules["data_validation"]

    # Go through data element validation for each column
    for column, rules in validation_rules.items():
        for rule_name, params in rules.items():
            invalid_mask = validate_column(df, column, rule_name, params, error_log)
            invalid_rows.extend(df[invalid_mask].index.tolist())

    # Drop invalid rows
    df = df.drop(index=invalid_rows)
    return df, error_log

def validate_column(df, column: str, rule_name: str, params: dict, error_log):
    """
    Validates a specific column in the dataset based on the given validation rule and logs any validation errors.

    Args:
        df (pandas.DataFrame): The dataset to validate.
        column (str): The column name to apply the validation rule to.
        rule_name (str): The name of the validation rule to apply.
        params (dict): The parameters for the validation rule.
        error_log (StringIO): A file-like object to log error messages.

    Returns:
        pandas.Series: A boolean Series indicating which rows failed the validation.
    """
    # Retrieve function based on data configuration file
    func = globals().get(rule_name)
    if func:
        # Apply validation for all values in the column - validation_results is a dataframe of whether the row passed validation
        validation_results = df[column].apply(lambda x: pd.isna(x) or not func(x, params))
        invalid_rows = df[validation_results]
        for index in invalid_rows.index:
            error_log.write(f"Column '{column}': Row {index} failed {rule_name} validation.\n")
        return validation_results
    else:
        error_log.write(f"Function {rule_name} does not exist. Please check the data configuration file.\n")
    return pd.Series([False] * len(df))

# Define validation helper functions
def validate_data_type(value, param: str = None):
    """
    Validates if a value matches the expected data type.

    Args:
        value (any): The value to validate.
        param (str, optional): The expected data type (e.g., "string", "int64", "float64").

    Returns:
        bool: True if the value matches the expected data type, otherwise False.
    """
    if param == "string":
        if isinstance(value, str):
            try:
                float(value)
                return False
            except ValueError:
                pass  
            if value.isdigit(): 
                return False 
            return True  # It's a valid string
        return False  # It's not a string
    elif param == "int64":
        return isinstance(value, int)
    elif param == "float64":
        return isinstance(value, float)
    return False  # Unsupported type / Invalid

def validate_length(value, params: dict = None):
    """
    Validates if the length of a value is within the specified range.

    Args:
        value (str): The value to validate.
        params (dict, optional): A dictionary containing 'min' and 'max' values for the length validation.

    Returns:
        bool: True if the length is within the specified range, otherwise False.
    """
    min, max = params["min"], params["max"]
    length = len(value)
    return (min is None or length >= min) and (max is None or length <= max)

def validate_range(value, params: dict = None):
    """
    Validates if a value is within the specified range.

    Args:
        value (numeric): The value to validate.
        params (dict, optional): A dictionary containing 'min' and 'max' values for the range validation.

    Returns:
        bool: True if the value is within the specified range, otherwise False.
    """
    min, max = params["min"], params["max"]
    return (min is None or value >= min) and (max is None or value <= max)

def validate_dp(value, params: dict = None):
    """
    Validates if the number of decimal places in a value is within the specified range.

    Args:
        value (numeric): The value to validate.
        params (dict, optional): A dictionary containing 'min' and 'max' values for the decimal places validation.

    Returns:
        bool: True if the number of decimal places is within the specified range, otherwise False.
    """
    min, max = params["min"], params["max"]
    decimal_places = len(str(value).split(".")[-1]) if '.' in str(value) else 0
    return (min is None or decimal_places >= min) and (max is None or decimal_places <= max)

def validate_nric(nric, param: str = None):
    """
    Validates if a value is a valid NRIC number.

    Args:
        nric (str): The NRIC number to validate.
        param (str, optional): An additional parameter, not used in this function.

    Returns:
        bool: True if the NRIC is valid, otherwise False.
    """
    return bool(nric and len(nric) == 9 and nric[0] in "SFTGM" and nric[1:8].isdigit() and nric[8].isalpha())

def validate_mandatory(value, param: str = None):
    """
    Validates if a value is not empty or missing (i.e., mandatory).

    Args:
        value (any): The value to validate.
        param (str, optional): An additional parameter, not used in this function.

    Returns:
        bool: True if the value is not missing or empty, otherwise False.
    """
    if pd.isna(value):  # Handles both None and pd.NA ** new addition 
        return False
    return value is not None and str(value).strip() != ""
