private _position = _this select 0;

private _spawnAreaAnchorPositions = [getPos theBase];

if (isMultiplayer) then {
    {
        _spawnAreaAnchorPositions pushBack getPos _x;
    } forEach playableUnits;
} else {
    _spawnAreaAnchorPositions pushBack getPos player;
};

//TODO points of interest

private _result = false;
scopeName "main";
{
    if (_position distance _x < JTC_spawnDistance) then {
        _result = true;
        breakTo "main";
    };
} forEach _spawnAreaAnchorPositions;
_result;