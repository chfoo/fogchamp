from util.readers.base import Reader


class EditorNotesReader(Reader):
    def read_move_notes(self):
        with self.read_csv('moves.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                yield row[0], row[1]

    def read_ability_notes(self):
        with self.read_csv('abilities.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                yield row[0], row[1]

    def add_move_notes(self, move_map: dict):
        for slug, note in self.read_move_notes():
            move_map[slug]['description'] += '\n✻ ' + note

    def add_ability_notes(self, ability_map: dict):
        for slug, note in self.read_ability_notes():
            ability_map[slug]['description'] += '\n✻ ' + note


