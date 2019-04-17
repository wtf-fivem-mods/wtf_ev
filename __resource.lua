client_scripts {
	'@wtf_redis/lib/redis.lua',

	'config.lua',

	'lib.lua',
	'debug.lua',

	'charger/client.lua',
	'hud/client.lua',
	'batt/client.lua',

    'garagedemo/db/db.lua',
    'garagedemo/db/redis.lua',
    'garagedemo/config.lua',
	'garagedemo/client.lua',
}

dependencies {
	"wtf_redis"
}