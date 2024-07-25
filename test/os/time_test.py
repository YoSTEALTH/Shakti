import time
import shakti


def test_Timeit():
    with shakti.Timeit(print=False) as t:
        # first
        t.start
        time.sleep(0.25)
        assert 0.25 < t.stop < 0.3

        # second
        t.start
        time.sleep(0.25)
        assert 0.25 < t.stop < 0.3

        # second
        t.start
        time.sleep(0.25)
        assert 0.25 < t.stop < 0.3

    # total time
    assert 0.75 < t.total_time < 0.8
