from math import floor, ceil

def calculate_percentile(prices: list[float], percentile: float) -> float:
    if not prices:
        raise ValueError("At least one price is required")
    if not 0 <= percentile <= 1:
        raise ValueError("percentile must be between 0 and 1")

    sorted_prices = sorted(prices)
    n = len(sorted_prices)

    if n == 1:
        return sorted_prices[0]

    position = (n - 1) * percentile  

    lower_index = floor(position)
    upper_index = ceil(position)

    # If the position is an integer, return the value at that index
    if lower_index == upper_index:
        return sorted_prices[lower_index]

    lower_price = sorted_prices[lower_index]
    upper_price = sorted_prices[upper_index]
    fraction = position - lower_index

    return lower_price + (upper_price - lower_price) * fraction


    # For example:
    # prices = [8.0, 10.0, 14.0, 20.0]
    # n = 4
    # for 33rd percentile(0.33):
    # position = (4 - 1) * 0.33 = 0.99
    # lower_index = floor(0.99) = 0
    # upper_index = ceil(0.99) = 1
    # lower_value = prices[0] = 8.0
    # upper_value = prices[1] = 10.0
    # fraction = 0.99 - 0 = 0.99
    # percentile_value = 8.0 + (10.0 - 8.0) * 0.99 
    #                  = 9.98

