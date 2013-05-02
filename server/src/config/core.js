/**
 * Core configuration.
 */

var config = {
	development: {
		socket: {
			subscribers: {
				port: 5223,
				logLevel: 0
			},
			publishers: {
				port: 5224,
				logLevel: 0
			}
		},
		rest: {
			port: 80
		},
		redis: {
			pubsub: {
				host: 'localhost',
				port: 6379
			},
			stats: {
				host: 'localhost',
				port: 6379
			},
			credentials: {
				host: 'localhost',
				port: 6379
			}
		}
	},
	production: {
		socket: {
			subscribers: {
				port: 5223,
				logLevel: 0,
				closeTimeout: 15
			},
			publishers: {
				port: 5224,
				logLevel: 0,
				closeTimeout: 15
			}
		},
		rest: {
			port: 80
		},
		redis: {
			pubsub: {
				host: 'localhost',
				port: 6379
			},
			stats: {
				host: 'localhost',
				port: 6379
			},
			credentials: {
				host: 'localhost',
				port: 6379
			}
		}
	}
};

// Export the object.
var env = process.env.NODE_ENV || 'development';
module.exports = config[env];