def is_palindrome(s):
    return s == s[::-1]

if __name__ == '__main__':
    assert is_palindrome("racecar") is True
    assert is_palindrome("hello") is False
    print("String palindrome test passed.")
