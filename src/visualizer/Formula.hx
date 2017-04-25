package visualizer;


import visualizer.dataset.DescriptionsDataset;
import visualizer.datastruct.MoveStats;
import visualizer.datastruct.PokemonStats;
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
    public static var FIXED_DAMAGE_MOVE = ["seismic-toss", "night-shade"];
    public static var WEIGHT_MOVE = ["low-kick", "grass-knot"];
    public static var HAPPINESS_MOVE = ["return", "frustration"];
    public static var VARIABLE_POWER_MOVE = ["magnitude"];

    static public function computeResult(
        userPokemonStat:PokemonStats, foePokemonStat:PokemonStats,
        userMoveStat:MoveStats, descriptionsDataset:DescriptionsDataset,
        formulaOptions:FormulaOptions
    ):DamageResult {
        var userMoveType:String = userMoveStat.moveType;
        var userTypes:Array<String> = userPokemonStat.types;
        var foeTypes:Array<String> = foePokemonStat.types;
        var factor = descriptionsDataset.getTypeEfficacy(userMoveType, foeTypes[0], foeTypes[1]);
        var userBasePower = Formula.computeBasePower(userPokemonStat, foePokemonStat, userMoveStat);
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
            var damageResultLow = Formula.computeDamage(userAttack, foeDefense, 10, stab, factor);
            var damageResultHigh = Formula.computeDamage(userAttack, foeDefense, 150, stab, factor);

            damageResult = {
                factor: factor,
                minHP: damageResultLow.minHP,
                maxHP: damageResultHigh.maxHP,
                critHP: damageResultHigh.critHP
            }
        } else {
            damageResult = Formula.computeDamage(userAttack, foeDefense, userBasePower, stab, factor);
        }

        if (userMoveStat.maxHits != null) {
            damageResult = Formula.modifyHits(damageResult, userMoveStat.minHits, userMoveStat.maxHits);
        }

        return damageResult;
    }

    static public function computeBasePower(userPokemonStat:PokemonStats, foePokemonStat:PokemonStats, userMoveStat:MoveStats):Int {
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
        }
        return userMoveStat.power;
    }

    static public function computeDamage(userAttack:Int, foeDefense:Int, userBasePower:Int, stab:Bool, damageFactor:Int):DamageResult {
        var modifier = damageFactor / 100;

        if (stab) {
            modifier *= 1.5;
        }

        var damage = ((2 * LEVEL + 10) / 250) * (userAttack / foeDefense) * userBasePower + 2;

        damage = damage * modifier;
        var minDamage = damage * RANDOM_MIN_MODIFIER;
        var critDamage = damage * CRIT_MODIFIER;

        return {
            factor: damageFactor,
            minHP: Std.int(Math.max(1, minDamage)),
            maxHP: Std.int(Math.max(1, damage)),
            critHP: Std.int(Math.max(1, critDamage))
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
