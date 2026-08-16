def factorial(n):
    return 1 if n <= 1 else n * factorial(n - 1)


if __name__ == '__main__':
    assert factorial(5) == 120
    print("Factorial test passed.")
