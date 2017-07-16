package visualizer;


import visualizer.datastruct.PokemonStats;
import visualizer.dataset.DescriptionsDataset;
import visualizer.datastruct.MoveStats;

typedef DamageResult = {
    factor: Int,
    minHP: Float,
    maxHP: Float,
    critHP: Float,
}

typedef DamageResultPercent = {
    factor: Int,
    minHP: Float,
    maxHP: Float,
    critHP: Float,
    minHPPercent: Int,
    maxHPPercent: Int,
    critHPPercent: Int,
}

class FormulaOptions {
    public var typeImmunities = true;

    public function new() {
    }
}


class Formula {
    public static var LEVEL = 100;
    public static var RANDOM_MIN_MODIFIER = 0.85;
    public static var CRIT_MODIFIER = 2.0;

    // TODO: use values in database generated from CSV
    public static var FIXED_DAMAGE_MOVE = ["seismic-toss", "night-shade"];
    public static var WEIGHT_MOVE = ["low-kick", "grass-knot"];
    public static var HAPPINESS_MOVE = ["return", "frustration"];
    public static var VARIABLE_POWER_MOVE = ["magnitude"];

    var descriptionsDataset:DescriptionsDataset;

    public function new(descriptionsDataset:DescriptionsDataset) {
        this.descriptionsDataset = descriptionsDataset;
    }

    public function computeResult(
        userPokemonStat:PokemonStats, foePokemonStat:PokemonStats,
        userMoveStat:MoveStats,
        formulaOptions:FormulaOptions
    ):DamageResult {
        var userMoveType:String = computeUserMoveType(userPokemonStat, userMoveStat);
        var userTypes:Array<String> = userPokemonStat.types;
        var foeTypes:Array<String> = foePokemonStat.types;
        var factor = descriptionsDataset.getTypeEfficacy(userMoveType, foeTypes[0], foeTypes[1]);
        var userBasePower = computeBasePower(userPokemonStat, foePokemonStat, userMoveStat);

        // TODO: check these from database
        var isVariableBasePower = Formula.VARIABLE_POWER_MOVE.indexOf(userMoveStat.slug) != -1;
        var isFixedDamageMove = Formula.FIXED_DAMAGE_MOVE.indexOf(userMoveStat.slug) != -1;

        if (!formulaOptions.typeImmunities && factor == 0) {
            factor = 100;
        }

        if (userBasePower == null && !isFixedDamageMove && !isVariableBasePower) {
            return {
                factor: factor,
                minHP: null,
                maxHP: null,
                critHP: null
            }
        }

        var userAttack;
        var foeDefense;

        if (userMoveStat.damageCategory == "physical") {
            userAttack = userPokemonStat.attack;
        } else {
            userAttack = userPokemonStat.specialAttack;
        }

        if (userMoveStat.damageCategory == "physical") {
            foeDefense = foePokemonStat.defense;
        } else {
            foeDefense = foePokemonStat.specialDefense;
        }

        var stab = userTypes.indexOf(userMoveType) != -1;
        var damageResult:DamageResult;

        if (isFixedDamageMove) {
            damageResult = {
                factor: factor,
                minHP: Formula.LEVEL,
                maxHP: Formula.LEVEL,
                critHP: Formula.LEVEL
            }
        } else if (isVariableBasePower) {
            var damageResultLow = computeDamage(userAttack, foeDefense, 10, stab, factor);
            var damageResultHigh = computeDamage(userAttack, foeDefense, 150, stab, factor);

            damageResult = {
                factor: factor,
                minHP: damageResultLow.minHP,
                maxHP: damageResultHigh.maxHP,
                critHP: damageResultHigh.critHP
            }
        } else {
            damageResult = computeDamage(userAttack, foeDefense, userBasePower, stab, factor);
        }

        if (userMoveStat.maxHits != null) {
            damageResult = Formula.modifyHits(damageResult, userMoveStat.minHits, userMoveStat.maxHits);
        }

        // TODO: give the valeus of all the parameters so it can be shown to user

        return damageResult;
    }

    public function computeUserMoveType(pokemonStat:PokemonStats, moveStats:MoveStats) {
        if (moveStats.slug == "natural-gift") {
            var itemInfo = descriptionsDataset.getItem(pokemonStat.item);

            if (itemInfo.naturalGiftType != null) {
                return itemInfo.naturalGiftType;
            }
        }
        return moveStats.moveType;
    }

    public function computeBasePower(userPokemonStat:PokemonStats, foePokemonStat:PokemonStats, userMoveStat:MoveStats):Int {
        switch (userMoveStat.slug) {
            case "low-kick" | "grass-knot":
                if (foePokemonStat.weight != null) {
                    return weightToPower(foePokemonStat.weight);
                }
            case "return":
                if (userPokemonStat.happiness != null) {
                    return Std.int(Math.max(1, userPokemonStat.happiness / 2.5));
                }
            case "frustration":
                if (userPokemonStat.happiness != null) {
                    return Std.int(Math.max(1, (255 - userPokemonStat.happiness) / 2.5));
                }
            case "fling":
                var itemInfo = descriptionsDataset.getItem(userPokemonStat.item);
                if (itemInfo != null) {
                    return itemInfo.flingPower;
                }
            case "natural-gift":
                var itemInfo = descriptionsDataset.getItem(userPokemonStat.item);
                if (itemInfo != null && itemInfo.naturalGiftType != null) {
                    return itemInfo.naturalGiftPower;
                }
        }
        return userMoveStat.power;
    }

    public function computeDamage(userAttack:Int, foeDefense:Int, userBasePower:Int, stab:Bool, damageFactor:Int):DamageResult {
        var modifier = damageFactor / 100;

        if (stab) {
            modifier *= 1.5;
        }

        var damage = ((2 * LEVEL + 10) / 250) * (userAttack / foeDefense) * userBasePower + 2;

        damage = damage * modifier;
        var minDamage = damage * RANDOM_MIN_MODIFIER;
        var critDamage = damage * CRIT_MODIFIER;

        damage = Math.floor(damage);
        minDamage = Math.floor(minDamage);
        critDamage = Math.floor(critDamage);

        if (damageFactor != 0) {
            damage = Math.max(1, damage);
            minDamage = Math.max(1, minDamage);
            critDamage = Math.max(1, critDamage);
        }

        return {
            factor: damageFactor,
            minHP: minDamage,
            maxHP: damage,
            critHP: critDamage
        }
    }

    static public function modifyHits(damageResult:DamageResult, minHits:Int, maxHits:Int):DamageResult {
        var minDamage = damageResult.minHP * minHits;
        var maxDamage = damageResult.maxHP * maxHits;
        var critDamage = damageResult.critHP * maxHits;

        return {
            factor: damageResult.factor,
            minHP: minDamage,
            maxHP: maxDamage,
            critHP: critDamage
        }
    }

    static public function resultsToPercentages(damageResult:DamageResult, foeHP:Int):DamageResultPercent {
        return {
            factor: damageResult.factor,
            minHP: damageResult.minHP,
            maxHP: damageResult.maxHP,
            critHP: damageResult.critHP,
            minHPPercent: Std.int(damageResult.minHP / foeHP * 100),
            maxHPPercent: Std.int(damageResult.maxHP / foeHP * 100),
            critHPPercent: Std.int(damageResult.critHP / foeHP * 100)
        }
    }

    static public function weightToPower(weight:Float):Int {
        if (weight < 10) {
            return 20;
        } else if (weight < 25) {
            return 40;
        } else if (weight < 50) {
            return 60;
        } else if (weight < 100) {
            return 80;
        } else if (weight < 200) {
            return 100;
        } else {
            return 120;
        }
    }
}
