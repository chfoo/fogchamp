import re
from util.readers.base import Reader
from util.readers.nkekev import slugify, rewrite_pokemon_name


class AddarashReader(Reader):
    def read_pbr_moveset(self, filename):
        with self.read_csv(filename) as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                (
                    name,
                    number,
                    item,
                    ability,
                    move_a,
                    move_b,
                    move_c,
                    move_d,
                    nature,
                    iv,
                    hp,
                    attack,
                    defense,
                    special_attack,
                    special_defense,
                    speed,
                    *dummy
                ) = row

                if not name.strip():
                    continue

                name = rewrite_pokemon_name(name)
                number = int(number)
                iv = int(number)
                hp = int(hp)
                attack = int(attack)
                defense = int(defense)
                special_attack = int(special_attack)
                special_defense = int(special_defense)
                speed = int(speed)

                happiness = None

                if item == '--':
                    item = ''

                moves = []

                for move in [move_a, move_b, move_c, move_d]:
                    if move and move != '--':
                        happiness_match = re.search(r' \((\d+|max)\)', move)

                        if happiness_match:
                            happiness = happiness_match.group(1)

                            if happiness == 'max':
                                # Max as in max frustration pp, not happiness
                                happiness = 0
                            else:
                                happiness = int(happiness)

                        moves.append(slugify(move))

                doc = {
                    'name': name,
                    'slug': slugify(name),
                    'number': number,
                    'ability': slugify(ability),
                    'moves': moves,
                    'iv': iv,
                    'hp': hp,
                    'attack': attack,
                    'defense': defense,
                    'special_attack': special_attack,
                    'special_defense': special_defense,
                    'speed': speed,
                    'nature': slugify(nature),
                    'item': slugify(item),
                    'happiness': happiness,
                }

                move_type_override_match = re.search(r'HP (\w+)', move_a)

                if move_type_override_match:
                    doc['move_type_override'] = slugify(move_type_override_match.group(1))

                yield doc

    def patch_pbr_moveset(self, docs, nkekev_reader, chfoo_reader):
        gender_map = {}

        for doc in chfoo_reader.read_pbr_seel(nkekev_reader):
            gender_map[doc['slug']] = doc['gender']

        for doc in docs:
            doc['gender'] = gender_map[doc['slug']]
            yield doc

    def read_pbr_gold_1_2(self, nkekev_reader, chfoo_reader):
        movesets = self.read_pbr_moveset('pbr-gold-1.2.csv')
        movesets = self.patch_pbr_moveset(movesets, nkekev_reader, chfoo_reader)

        return movesets
