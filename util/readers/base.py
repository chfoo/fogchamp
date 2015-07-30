import contextlib
import csv
import os


class Reader(object):
    def __init__(self, root_dir):
        self._root_dir = root_dir

    @contextlib.contextmanager
    def read_csv(self, filename):
        path = os.path.join(self._root_dir, filename)

        with open(path, newline='') as csvfile:
            reader = csv.reader(csvfile)

            yield reader
