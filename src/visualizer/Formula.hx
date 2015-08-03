package visualizer;


typedef DamageResult = {
    minHP: Float,
    maxHP: Float,
    critHP: Float,
}

typedef DamageResultPercent = {
    minHP: Float,
    maxHP: Float,
    critHP: Float,
    minHPPercent: Int,
    maxHPPercent: Int,
    critHPPercent: Int,
}


class Formula {
    public static var LEVEL = 100;
    public static var RANDOM_MIN_MODIFIER = 0.85;
    public static var CRIT_MODIFIER = 2.0;

    static public function computeBasePower(userPokemonStat:Dynamic, foePokemonStat:Dynamic, userMoveStat:Dynamic):Int {
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
            minHP: minDamage,
            maxHP: maxDamage,
            critHP: critDamage
        }
    }

    static public function resultsToPercentages(damageResult:DamageResult, foeHP:Int):DamageResultPercent {
        return {
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
