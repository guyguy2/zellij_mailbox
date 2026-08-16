def get_worker_status():
    return "DEV_READY"

if __name__ == "__main__":
    assert get_worker_status() == "DEV_READY"
    print("dev_check: PASSED")
