import collections
from util.readers.base import Reader


DAMAGE_CATEGORY_MAP = {
    1: 'status',
    2: 'physical',
    3: 'special',
}


class PokedexReader(Reader):
    def read_types_map(self):
        types_map = {}

        with self.read_csv('types.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                id_num = int(row[0])
                slug = row[1]

                types_map[id_num] = slug

        return types_map

    def read_moves(self):
        types_map = self.read_types_map()
        move_name_map = self.read_move_names()
        move_desc_map = self.read_move_descriptions()
        move_meta_map = self.read_move_meta()

        with self.read_csv('moves.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                move_id = int(row[0])
                slug = row[1]
                move_type = types_map[int(row[3])]
                power = row[4]
                pp = row[5]
                accuracy = row[6]
                damage_category = DAMAGE_CATEGORY_MAP[int(row[9])]

                power = int(power) if power else '--'
                pp = int(pp) if pp else '--'
                accuracy = int(accuracy) if accuracy else '--'

                doc = {
                    'slug': slug,
                    'move_type': move_type,
                    'power': power,
                    'pp': pp,
                    'accuracy': accuracy,
                    'damage_category': damage_category,
                    'name': move_name_map[move_id],
                    'description': move_desc_map.get(move_id)
                }

                doc.update(move_meta_map.get(move_id, {}))

                yield doc

    def read_move_names(self, lang=9):
        move_name_map = {}

        with self.read_csv('move_names.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                move_id, row_lang, name = row
                move_id = int(move_id)
                row_lang = int(row_lang)

                if row_lang != lang:
                    continue

                move_name_map[move_id] = name

        return move_name_map

    def read_move_meta(self):
        move_meta_map = {}

        with self.read_csv('move_meta.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                move_id = int(row[0])
                min_hits = int(row[3]) if row[3] else None
                max_hits = int(row[4]) if row[4] else None

                move_meta_map[move_id] = {
                    'min_hits': min_hits,
                    'max_hits': max_hits,
                }

        return move_meta_map

    def read_move_descriptions(self, lang=9):
        move_desc_map = {}

        with self.read_csv('move_flavor_text.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                effect_id = int(row[0])
                lang_id = int(row[2])
                description = row[3]

                if lang_id != lang:
                    continue

                move_desc_map[effect_id] = description

        # with self.read_csv('move_effect_prose.csv') as reader:
        #     for index, row in enumerate(reader):
        #         if index == 0:
        #             continue
        #
        #         effect_id = int(row[0])
        #         description = row[2]
        #
        #         move_desc_map[effect_id] = description

        return move_desc_map

    def read_pokemon_types(self):
        types_map = self.read_types_map()
        pokemon_types = {}

        with self.read_csv('pokemon_types.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                pokemon_num = int(row[0])
                pokemon_type = types_map[int(row[1])]

                if pokemon_num not in pokemon_types:
                    pokemon_types[pokemon_num] = []

                pokemon_types[pokemon_num].append(pokemon_type)

        return pokemon_types

    def read_abilities(self):
        name_map = self.read_ability_names()
        desc_map = self.read_ability_descriptions()

        with self.read_csv('abilities.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id = int(row[0])
                slug = row[1]

                yield {
                    'slug': slug,
                    'name': name_map[ability_id],
                    'description': desc_map.get(ability_id)
                }

    def read_ability_names(self, lang=9):
        name_map = {}

        with self.read_csv('ability_names.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id, row_lang, name = row
                ability_id = int(ability_id)
                row_lang = int(row_lang)

                if row_lang != lang:
                    continue

                name_map[ability_id] = name

        return name_map

    def read_ability_descriptions(self, lang=9):
        desc_map = {}

        with self.read_csv('ability_flavor_text.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                ability_id = int(row[0])
                lang_id = int(row[2])
                description = row[3]

                if lang_id != lang:
                    continue

                desc_map[ability_id] = description

        return desc_map

    def read_type_efficacy(self):
        types_map = self.read_types_map()
        efficacy_map = collections.defaultdict(dict)

        with self.read_csv('type_efficacy.csv') as reader:
            for index, row in enumerate(reader):
                if index == 0:
                    continue

                user = types_map[int(row[0])]
                foe = types_map[int(row[1])]
                damage_factor = int(row[2])

                # Downgrade to gen 4
                if foe == 'steel' and user in ('ghost', 'dark'):
                    damage_factor = 100

                efficacy_map[user][foe] = damage_factor

        return efficacy_map
