import re

from util.readers.base import Reader


class NkekevReader(Reader):
    def read_pbr_moveset(self, filename):
        with self.read_csv(filename) as reader:
            prev_number = None

            for index, row in enumerate(reader):
                if index == 0:
                    continue

                (
                    gender,
                    number,
                    name,
                    ability,
                    move_a,
                    move_b,
                    move_c,
                    move_d,
                    iv,
                    hp,
                    attack,
                    defense,
                    special_attack,
                    special_defense,
                    speed,
                    nature,
                    item,
                    *dummy
                ) = row

                if not name:
                    continue

                name = rewrite_pokemon_name(name)
                number = int(number or prev_number)
                iv = int(number)
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

                yield {
                    'gender': gender,
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
                }

                prev_number = number

    def read_pbr_platinum(self):
        return self.read_pbr_moveset('pbr-platinum.csv')


def rewrite_pokemon_name(name):
    name = name.replace('♀', '-F').replace('♂', '-M')

    if name.startswith('Shiny '):
        return '{} (Shiny)'.format(name.replace('Shiny ', ''))

    return name


def slugify(name):
    name = name.strip()

    if name.startswith('Hidden Power'):
        name = 'Hidden Power'
    elif name == 'Aurasphere':
        name = 'Aura Sphere'
    elif name == 'DynamicPunch':
        name = 'Dynamic Punch'
    elif name == 'Solarbeam':
        name = 'Solar Beam'
    elif name == 'Recovery':
        name = 'Recover'

    name = re.sub(r' \((\d+|max)\)', '', name)  # Things like "Frustation (90)"
    name = name.lower().replace(' ', '-')
    name = name.replace('toxik', 'toxic')
    name = re.sub(r'[^a-zA-Z0-9-]', '', name)
    return name
