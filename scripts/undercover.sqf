JTC_undercoverMode = "civilian"; // not, civilian, enemy
JTC_vehiclesKnownToEnemy = [];
JTC_notUndercoverPlayers = [];
player setCaptive true;
waitUntil {
    sleep 1;
    !isNil("JTC_missionStarted");
};
while {true} do {
    sleep 5;
    private _newUndercoverMode = "not";
    private _notUndercoverReasons = [];
    private _playerPosition = position player;
    private _vest = vest player;
    private _uniform = uniform player;
    private _hmd = hmd player;
    private _headgear = headgear player;
    private _weaponEquipped = (primaryWeapon player) != "" || (handgunWeapon player) != "" || (secondaryWeapon player) != "";
    private _playerVehicle = vehicle player;
    private _playerLooksCivilian = _vest == "" && _hmd == "" && !(_headgear in JTC_helmets) &&
        (_uniform in JTC_civilianUniforms || _uniform == "") && !_weaponEquipped;
    private _playerInCleanCivilianVehicle = (JTC_civilianFaction == (faction _playerVehicle)) and (-1 == JTC_vehiclesKnownToEnemy find _playerVehicle);
    if (vehicle player == player) then {
        if (_playerLooksCivilian) then {
            _newUndercoverMode = "civilian";
        } else {
            _notUndercoverReasons pushBack "STR_JTC_undDoesNotLookCivilian";
//            TODO Implement undercover enemy #71
//            if (_uniform in JTC_enemyUniforms) then {
//                _newUndercoverMode = "enemy";
//            };
        };
    } else {
        if (_playerInCleanCivilianVehicle) then {
            private _vehicleRole = assignedVehicleRole player;
            if (_playerLooksCivilian or (_vehicleRole select 0 != "cargo") or (1 == count _vehicleRole)) then {
                _newUndercoverMode = "civilian";
            } else {
                _notUndercoverReasons pushBack "STR_JTC_undVisibleInVehicle";
            };
        } else {
            _notUndercoverReasons pushBack "STR_JTC_undVehicleNotClean";
        };
    };
    if (JTC_undercoverMode == "not" and _newUndercoverMode != "not") then {
        private _enemyKnowsAboutPlayer = player call JTC_fnc_enemyKnowsAboutObject;
        if (_enemyKnowsAboutPlayer select 0 > 0.05 and _enemyKnowsAboutPlayer select 1  < 300) then {
            _newUndercoverMode = "not";
            _notUndercoverReasons pushBack "STR_JTC_undEnemyKnows";
        };
    };

    if (_newUndercoverMode == "civilian" and !isNil("JTC_enemyBases")) then {
        {
            if (_playerPosition inArea (_x select 0)) then {
                _newUndercoverMode = "not";
                _notUndercoverReasons pushBack "STR_JTC_undEnemyBase";
            };
        } forEach JTC_enemyBases;
    };

    if (_newUndercoverMode != "not" and alive player) then {
        scopeName "main";
        {
            if ((_playerPosition distance position _x) < 20) then {
                _newUndercoverMode = "not";
                _notUndercoverReasons pushBack "STR_JTC_undExplosive";
                breakTo "main";
            }
        } forEach getAllOwnedMines player;
    };

    if (_newUndercoverMode != "not" and alive player) then {
        scopeName "main";
        {
            if (faction _x == JTC_enemyFaction and !alive _x) then {
                _newUndercoverMode = "not";
                _notUndercoverReasons pushBack "STR_JTC_undCorpse";
                breakTo "main";
            };
        } forEach (_playerPosition nearObjects ["man", 15]);
    };

    if (_newUndercoverMode != "not" and alive player) then {
        scopeName "main";
        {
            if (alive _x) then {
                if (player != _x and (_playerPosition distance position _x) < 30) then {
                    _newUndercoverMode = "not";
                    _notUndercoverReasons pushBack "STR_JTC_undNearNotUnd";
                    breakTo "main";
                };
            } else {
                if (player != _x and (_playerPosition distance position _x) < 15) then {
                    _newUndercoverMode = "not";
                    _notUndercoverReasons pushBack "STR_JTC_undNearDeadNotUnd";
                    breakTo "main";
                };
            };
        } forEach JTC_notUndercoverPlayers;
    };

    if (_newUndercoverMode != "not" and alive player and _playerInCleanCivilianVehicle and !isNil("JTC_enemyBases")) then {
        scopeName "main";
        if (!(_playerVehicle isKindOf "Air")) then {
            if (count (_playerVehicle nearRoads 20) == 0) then {
                {
                    if ("ok" == (_x select 3) and (_playerPosition distance2D markerPos (_x select 0)) < 700) then {
                        _newUndercoverMode = "not";
                        _notUndercoverReasons pushBack "STR_JTC_undOffroad";
                        breakTo "main";
                    };
                } forEach JTC_enemyBases;
            };
        };
    };

    if (_playerInCleanCivilianVehicle and _newUndercoverMode == "not") then {
        private _enemyKnowsAboutVehicle = _playerVehicle call JTC_fnc_enemyKnowsAboutObject;
        if (_enemyKnowsAboutVehicle select 0 > 0.05 and _enemyKnowsAboutVehicle select 1  < 300) then {
            JTC_vehiclesKnownToEnemy pushBackUnique _playerVehicle;
            publicVariable "JTC_vehiclesKnownToEnemy";
            ["vehicle %1 is now known to enemy", _playerVehicle] call JTC_fnc_log;
        };
    };

    if (_newUndercoverMode == "not") then {
        if ((count _notUndercoverReasons) == 1 and (_notUndercoverReasons select 0) == "STR_JTC_undNearNotUnd") then {
            JTC_notUndercoverPlayers = JTC_notUndercoverPlayers - [player];
        } else {
            JTC_notUndercoverPlayers pushBackUnique player;
        }
    } else {
        JTC_notUndercoverPlayers = JTC_notUndercoverPlayers - [player];
    };
    publicVariable "JTC_notUndercoverPlayers";
    if (_newUndercoverMode == "not" and JTC_undercoverMode != "not") then {
        hint localize (_notUndercoverReasons select 0);
    };
    JTC_undercoverMode = _newUndercoverMode;

    if (JTC_undercoverMode == "not") then {
        ["Not undercover reasons: %1", _notUndercoverReasons] call JTC_fnc_log;
        player setCaptive false;
    } else {
        player setCaptive true;
    };
}

