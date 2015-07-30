package visualizer;


class Formula {
    static var LEVEL = 100;

    static public function computeDamage(userAttack:Int, foeDefense:Int, userBasePower:Int, stab:Bool, damageFactor:Int):Int {
        var modifier = damageFactor / 100;

        if (stab) {
            modifier *= 1.5;
        }

        var damage = ((2 * LEVEL + 10) / 250) * (userAttack / foeDefense) * userBasePower + 2;

        return Std.int(damage * modifier);
    }
}
