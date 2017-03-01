import re
from util.readers.base import Reader
from util.readers.nkekev import slugify, rewrite_pokemon_name


class AddarashReader(Reader):
    def read_pbr_moveset(self, filename, has_iv=True):
        with self.read_csv(filename) as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                if has_iv:
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
                else:
                    (
                        name,
                        number,
                        item,
                        ability,
                        move_a,
                        move_b,
                        move_c,
                        move_d,
                        hp,
                        attack,
                        defense,
                        special_attack,
                        special_defense,
                        speed,
                        *dummy
                    ) = row
                    iv = None
                    nature = None

                if not name.strip():
                    continue

                name = rewrite_pokemon_name(name)
                number = int(number)
                iv = int(iv) if iv else None
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
                        happiness_match = re.search(r' \((\d+( [bB][pP])?|max)\)', move)

                        if happiness_match:
                            happiness = happiness_match.group(1)

                            if happiness == 'max':
                                # Max as in max frustration pp, not happiness
                                happiness = 0
                            else:
                                happiness = happiness.split()[0]
                                happiness = int(happiness)

                        moves.append(slugify(move))
                        assert '-bp' not in slugify(move), (name, number, move)

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
                    'nature': slugify(nature) if nature else None,
                    'item': slugify(item),
                    'happiness': happiness,
                }

                move_type_override_match = re.search(r'HP (\w+)', move_a)

                if move_type_override_match:
                    doc['move_type_override'] = slugify(move_type_override_match.group(1))

                yield doc

    def patch_pbr_moveset(self, docs, nkekev_reader, chfoo_reader):
        gender_map = {}
        hp_map = {}
        iv_map = {}

        for doc in chfoo_reader.read_pbr_seel(nkekev_reader):
            gender_map[doc['slug']] = doc['gender']

        for doc in nkekev_reader.read_pbr_platinum():
            hp_map[doc['slug']] = doc['hp']
            iv_map[doc['slug']] = doc['iv']

        for doc in docs:
            doc['gender'] = gender_map[doc['slug']]

            if doc['hp'] is None:
                doc['hp'] = hp_map[doc['slug']]
                doc['iv'] = iv_map[doc['slug']]

            yield doc

    def read_pbr_gold_1_2(self, nkekev_reader, chfoo_reader):
        movesets = self.read_pbr_moveset('pbr-gold-1.2.csv')
        movesets = self.patch_pbr_moveset(movesets, nkekev_reader, chfoo_reader)

        return movesets

    def read_pbr_gold_1_2_2015_11_07(self, nkekev_reader, chfoo_reader):
        movesets = self.read_pbr_moveset('pbr-gold-1.2-2015-11-07.csv')
        movesets = self.patch_pbr_moveset(movesets, nkekev_reader, chfoo_reader)

        return movesets

    def read_pbr_2_0(self, nkekev_reader, chfoo_reader):
        movesets = self.read_pbr_moveset('pbr-2.0.csv', has_iv=False)
        movesets = self.patch_pbr_moveset(movesets, nkekev_reader, chfoo_reader)

        return movesets
