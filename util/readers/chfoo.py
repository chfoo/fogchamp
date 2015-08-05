import re
from util.readers.base import Reader
from util.readers.nkekev import slugify


NUMBER_NAME_REWRITE_MAP = {
    '386': 'Deoxys-normal',
    '412': 'Burmy-plant',
    '413': 'Wormadam-plant',
    '422': 'Shellos-east',
    '423': 'Gastrodon-east',
    '493': 'Arceus-normal',
}


class ChfooReader(Reader):
    def read_pbr_moveset(self, filename):
        with self.read_csv(filename) as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                (
                    gender,
                    number,
                    name,
                    move_a,
                    move_b,
                    move_c,
                    move_d,
                    ability,
                    item,
                    hp,
                    attack,
                    defense,
                    special_attack,
                    special_defense,
                    speed,
                ) = row

                if number in NUMBER_NAME_REWRITE_MAP:
                    name = NUMBER_NAME_REWRITE_MAP[number]

                number = int(re.match(r'(\d+)', number).group(1))
                hp = int(hp)
                attack = int(attack)
                defense = int(defense)
                special_attack = int(special_attack)
                special_defense = int(special_defense)
                speed = int(speed)

                moves = []

                for move in [move_a, move_b, move_c, move_d]:
                    if move:
                        moves.append(slugify(move))

                doc = {
                    'gender': gender,
                    'name': rewrite_name(name),
                    'slug': slugify(rewrite_name(name)),
                    'number': number,
                    'moves': moves,
                    'hp': hp,
                    'attack': attack,
                    'defense': defense,
                    'special_attack': special_attack,
                    'special_defense': special_defense,
                    'speed': speed,
                    'ability': slugify(ability),
                    'item': slugify(item),
                }

                yield doc

    def patch_pbr_moveset(self, docs, nkekev_reader):
        happiness_map = {}
        move_type_override_map = {}

        for doc in nkekev_reader.read_pbr_platinum():
            happiness_map[doc['slug']] = doc['happiness']

            if 'move_type_override' in doc:
                move_type_override_map[doc['slug']] = doc['move_type_override']

        for doc in docs:
            doc['happiness'] = happiness_map[doc['slug']]

            if doc['slug'] in move_type_override_map:
                doc['move_type_override'] = move_type_override_map[doc['slug']]

            yield doc

    def read_pbr_seel(self, nkekev_reader):
        movesets = self.read_pbr_moveset('pbr-seel.csv')
        movesets = self.patch_pbr_moveset(movesets, nkekev_reader)

        return movesets


def rewrite_name(name):
    name = name.replace('-female', '-f')
    name = name.replace('-male', '-m')
    name = re.sub(r'-(\w{2,})', r' (\1)', name)
    name = name.title()

    return name
