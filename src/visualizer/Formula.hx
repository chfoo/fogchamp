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
    static var LEVEL = 100;
    static var RANDOM_MIN_MODIFIER = 0.85;
    static var CRIT_MODIFIER = 2.0;

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
}
