var redis = require('redis');
var config = require('../config');
var utils = require('./utils');
var slug = require('slug');
var step = require('step');

var store = redis.createClient(config.core.redis.credentials.port, config.core.redis.credentials.host);

function create(channel, email, callback) {
	callback = callback || function() {};
	channel = slug(channel);

	store.exists(channel + ':api', function(err, res) {
		if (err) {
			return callback(new Error('ApplicationError'), undefined);
		}

		if (res == 1) {
			return callback(new Error('ChannelAlreadyExists'), undefined);
		}

		// Create a transaction
		var trans = store.multi();

		var apiToken = utils.hash();
		var pubToken = utils.hash();
		var subToken = utils.hash();

		store.hmset(channel + ':api', 'token', apiToken, 'email', email);
		store.hset(channel + ':publishers', pubToken, JSON.stringify(['*']));
		store.hset(channel + ':subscribers', subToken, JSON.stringify(['*']));

		// Execute transaction
		trans.exec(function(err, results) {
			if (err) {
				return callback(new Error('ApplicationError'), undefined);
			}

			callback(undefined, {
				channel: channel,
				api: {
					token: apiToken,
					email: email
				},
				tokens: {
					publishers: pubToken,
					subscribers: subToken
				}
			});
		});
	});
}

function tokens(channel, apiToken, callback) {
	callback = callback || function() {};
	channel = slug(channel);

	owner(channel, apiToken, function(err, res) {
		if (err) {
			return callback(err, undefined);
		}

		step(
			function() {
				store.hgetall(channel + ':api', this.parallel());
				store.hgetall(channel + ':publishers', this.parallel());
				store.hgetall(channel + ':subscribers', this.parallel());
			},
			function(err, api, publishers, subscribers) {
				if (err) {
					return callback(new Error('ApplicationError'), undefined);
				}

				callback(undefined, {
					channel: channel,
					api: api,
					tokens: {
						publishers: publishers,
						subscribers: subscribers
					}
				});
			}
		);
	});
}

function addToken(channel, apiToken, type, perms, callback) {
	callback = callback || function() {};
	channel = slug(channel);
	perms = perms || '';

	var permissions = perms.split(',');
	for (var i = 0; i < permissions.length; i++) {
		permissions[i] = permissions[i].trim();
	}

	// TODO: Check type and perms

	owner(channel, apiToken, function(err, res) {
		if (err) {
			return callback(err, undefined);
		}

		var token = utils.hash();

		step(
			function() {
				store.hset(channel + ':' + type, token, JSON.stringify(permissions), this);
			},
			function(err, res) {
				if (err) {
					return callback(new Error('ApplicationError'), undefined);
				}

				callback(undefined, {
					channel: channel,
					token: token,
					permissions: permissions
				});
			}
		);
	});
}

function removeToken(channel, apiToken, type, token, callback) {
	callback = callback || function() {};
	channel = slug(channel);

	// TODO: Check type and token

	owner(channel, apiToken, function(err, res) {
		if (err) {
			return callback(err, undefined);
		}

		step(
			function() {
				store.hdel(channel + ':' + type, token, this);
			},
			function(err, res) {
				if (err) {
					return callback(new Error('ApplicationError'), undefined);
				}

				callback(undefined, {
					channel: channel,
					token: token
				});
			}
		);
	});
}

function remove(channel, apiToken, callback) {
	callback = callback || function() {};
	channel = slug(channel);

	owner(channel, apiToken, function(err, res) {
		if (err) {
			return callback(err, undefined);
		}

		step(
			function() {
				store.del(channel + ':api', this.parallel());
				store.del(channel + ':publishers', this.parallel());
				store.del(channel + ':subscribers', this.parallel());
			},
			function(err, res) {
				if (err) {
					return callback(new Error('ApplicationError'), undefined);
				}

				callback(undefined, {
					channel: channel
				});
			}
		);
	});
}

function owner(channel, apiToken, callback) {
	callback = callback || function() {};

	if (!channel || !apiToken) {
		return callback(new Error('AuthInvalidFields'), undefined);
	}

	store.hget(channel + ':api', 'token', function(err, res) {
		if (!err && res && res == apiToken) {
			// All good
			return callback(undefined, true);
		} else {
			return callback(new Error('AuthInvalidCredentials', false));
		}
	});
}

function verify(data, callback) {
	callback = callback || function() {};

	if (!data || !data.type || !data.channel || !data.secret) {
		return callback(new Error('AuthInvalidFields'), undefined);
	}

	store.hget(data.channel + ':' + data.type, data.secret, function(err, res) {
		if (!err && res) {
			// All good
			return callback(undefined, JSON.parse(res));
		} else {
			return callback(new Error('AuthInvalidCredentials', undefined));
		}
	});
}

module.exports = {
	create: create,
	tokens: tokens,
	addToken: addToken,
	removeToken: removeToken,
	verify: verify,
	remove: remove
};
