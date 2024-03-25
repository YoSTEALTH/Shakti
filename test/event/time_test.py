import time
import shakti


def test_time():
    assert time.time() < shakti.time() < time.time()


def test_Timeit():
    with shakti.Timeit(print=False) as t:
        # first
        t.start
        time.sleep(0.25)
        assert 0.25 < t.stop < 0.27

        # second
        t.start
        time.sleep(0.25)
        assert 0.25 < t.stop < 0.27

        # second
        t.start
        time.sleep(0.25)
        assert 0.25 < t.stop < 0.27

    # total time
    assert 0.75 < t.total_time < 0.77
