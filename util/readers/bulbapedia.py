from util.readers.base import Reader
from util.readers.nkekev import slugify


class BulbapediaReader(Reader):
    def read_accuracy_changes(self):
        with self.read_csv('accuracy_changes.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                name, gen_4, gen_5, gen_6 = row

                gen_4 = int(gen_4) if gen_4 else None
                gen_5 = int(gen_5) if gen_5 else None
                gen_6 = int(gen_6) if gen_6 else None

                yield name, gen_4, gen_5, gen_6

    def read_power_changes(self):
        with self.read_csv('power_changes.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                name, gen_4, gen_5, gen_6 = row

                gen_4 = int(gen_4) if gen_4 else None
                gen_5 = int(gen_5) if gen_5 else None
                gen_6 = int(gen_6) if gen_6 else None

                yield name, gen_4, gen_5, gen_6

    def get_accuracy_map(self):
        accuracy_map = {}

        for row in self.read_accuracy_changes():
            move_slug = slugify(row[0])
            accuracy = row[1] or row[2]

            if accuracy:
                accuracy_map[move_slug] = accuracy

        return accuracy_map

    def get_power_map(self):
        power_map = {}

        for row in self.read_power_changes():
            move_slug = slugify(row[0])
            power = row[1] or row[2]

            if power:
                power_map[move_slug] = power

        return power_map

    def downgrade_move_changes(self, move_stats):
        accuracy_map = self.get_accuracy_map()
        power_map = self.get_power_map()

        for slug, stats in move_stats.items():
            if slug in accuracy_map:
                stats['accuracy'] = accuracy_map[slug]

            if slug in power_map:
                stats['power'] = power_map[slug]
