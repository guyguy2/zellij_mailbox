def is_anagram(s1, s2):
    return sorted(s1.replace(" ", "").lower()) == sorted(s2.replace(" ", "").lower())

if __name__ == '__main__':
    assert is_anagram("listen", "silent") is True
    assert is_anagram("hello", "world") is False
    print("Anagram test passed.")
