"""Lightweight test utility script to verify worker hook execution."""

def test_basic_arithmetic():
    assert 2 + 2 == 4
    assert 10 - 3 == 7
    assert 3 * 5 == 15
    assert 20 / 4 == 5

if __name__ == "__main__":
    test_basic_arithmetic()
    print("All smoke tests passed successfully.")
