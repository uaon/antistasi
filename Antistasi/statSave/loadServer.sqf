#include "../macros.hpp"
AS_SERVER_ONLY("statSave/loadServer.sqf");
params ["_saveName"];

petros allowdamage false;

[_saveName] call AS_fnc_loadPersistents;
[_saveName] call AS_fnc_loadArsenal;
[_saveName] call AS_fnc_loadMarkers;
[true] call fnc_MAINT_arsenal;

[_saveName, "destroyedCities"] call fn_LoadStat; publicVariable "destroyedCities";
[_saveName, "minas"] call fn_LoadStat;
[_saveName, "cuentaCA"] call fn_LoadStat;
[_saveName, "fecha"] call fn_LoadStat;
[_saveName, "smallCAmrk"] call fn_LoadStat;
[_saveName, "miembros"] call fn_LoadStat;
[_saveName, "vehInGarage"] call fn_LoadStat;

[_saveName] call AS_fnc_location_load;

{
	if (_x in destroyedCities) then {
		[_x] call destroyCity;
	};
} forEach (call AS_fnc_location_all);

{
	[_x] call powerReorg;
} forEach ("powerplant" call AS_fnc_location_T);

[_saveName] call AS_fnc_loadAAFarsenal;
[_saveName] call AS_fnc_loadHQ;
[_saveName, "estaticas"] call fn_LoadStat;//tiene que ser el último para que el sleep del borrado del contenido no haga que despawneen

if (isMultiplayer) then {
	{
        _jugador = _x;
        if ([_jugador] call isMember) then
            {
            {_jugador removeMagazine _x} forEach magazines _jugador;
            {_jugador removeWeaponGlobal _x} forEach weapons _jugador;
            removeBackpackGlobal _jugador;
            };
        _pos = (getMarkerPos "FIA_HQ") findEmptyPosition [2, 10, typeOf (vehicle _jugador)];
        _jugador setPos _pos;
	} forEach playableUnits;

    call AS_fnc_loadPlayers;

} else {
	{player removeMagazine _x} forEach magazines player;
	{player removeWeaponGlobal _x} forEach weapons player;
	removeBackpackGlobal player;

	_pos = (getMarkerPos "FIA_HQ") findEmptyPosition [2, 10, typeOf (vehicle player)];
	player setPos _pos;
};

[[_saveName, "BE_data"] call fn_LoadStat] call fnc_BE_load;

diag_log format ['[AS] Server: game "%1" loaded', _saveName];
petros allowdamage true;

// resume existing attacks in 25 seconds.
[_saveName] spawn {
    params ["_saveName"];
    sleep 25;
    [_saveName, "tasks"] call fn_LoadStat;

    _tmpCAmrk = + smallCAmrk;
    smallCAmrk = [];

    {
		private _position = (_x call AS_fnc_location_position);
    	_base = [_position] call findBasesForCA;
    	_radio = _position call radioCheck;
    	if ((_base != "") and (_radio) and (_x in mrkFIA) and (not(_x in smallCAmrk))) then {
        	[_x] remoteExec ["patrolCA",HCattack];
        	smallCAmrk pushBackUnique _x;
        };
    } forEach _tmpCAmrk;
    publicVariable "smallCAmrk";
};