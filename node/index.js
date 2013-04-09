var io = require('socket.io-client');

var socketOptions = {
	transports: ['websocket'],
	'force new connection': true,
	'reconnection delay': 100,
	'reconnection limit': 3000,
	'max reconnection attempts': Infinity
};

var config = {
	host: 'api.hatchet.io',
	ports: {
		subscribers: 5223,
		publishers: 5224
	}
};

function HatchetPublisher(channel, secret, opts) {
	var self = this;
	var con;
	opts = opts || {};

	// Options
	var options = {
		log: !!opts.log,
		host: typeof opts.host == 'string' ? opts.host : config.host,
		port: typeof opts.port == 'string' ? opts.port : config.ports.publishers
	};

	// Auth Credentials
	var auth = {
		channel: channel,
		secret: secret
	};

	var queue = [];
	var authenticated = false;

	function client() {
		if (con) { return con; }

		con = io.connect('http://' + options.host + ':' + options.port, socketOptions);
		con.on('connect', function () {
			log('connected', con.socket.sessionid);
			con.emit('authenticate', auth);
		});
		con.on('authenticated', function () {
			log('authenticated', con.socket.sessionid);
			authenticated = true;
			flush();
		});
		con.on('deauthenticated', function () {
			log('deauthenticated', con.socket.sessionid);
			authenticated = false;
		});
		con.on('disconnect', function () {
			log('disconnect', con.socket.sessionid );
		});
		con.on('reconnect_failed', function() {
			log('reconnect failed', con.socket.sessionid);
		});
		con.on('auth-error', function () {
			log('auth-error', con.socket.sessionid);
		});
		con.on('auth-invalid', function () {
			log('auth-invalid', con.socket.sessionid);
		});
		con.on('auth-invalid-perms', function () {
			log('auth-invalid-perms', con.socket.sessionid);
		});
		return con;
	}

	function broadcast(event, data) {
		if (!event) { return; }
		data = data || {};
		_deliver({ event: event, data: data });
	}

	function send(target, event, data) {
		if (!event || !target) { return; }
		data = data || {};
		_deliver({ event: event, target: target, data: data });
	}

	function once(event, data) {
		if (!event) { return; }
		data = data || {};
		_deliver({ event: event, once: true, data: data });
	}

	function _deliver(item) {
		var socket = client();
		if (authenticated) {
			socket.emit('push', item);
		} else {
			queue.push(item);
		}
	}

	function flush() {
		var socket = client();
		while (queue.length) {
			var item = queue.shift();
			socket.emit('push', item);
		}
	}

	function log() {
		if (options.log){
			console.log('hatchet.io :: publisher :: ', Array.prototype.slice.call(arguments));
		}
	}

	// Expose public methods
	this.once = once;
	this.broadcast = broadcast;
	this.send = send;
	this.authenticated = authenticated;
}

function HatchetSubscriber(channel, secret, opts) {
	var self = this;
	var con;
	opts = opts || {};

	// Options
	var options = {
		log: !!opts.log,
		host: typeof opts.host == 'string' ? opts.host : config.host,
		port: typeof opts.port == 'string' ? opts.port : config.ports.subscribers
	};

	// Auth Credentials
	var auth = {
		channel: channel,
		secret: secret
	};

	var queue = [];
	var aliasName;
	var watching = {};
	var authenticated = false;

	function client() {
		if (con) { return con; }

		con = io.connect('http://' + options.host + ':' + options.port, socketOptions);
		con.on('connect', function () {
			log('connected', con.socket.sessionid);
			con.emit('authenticate', auth);
		});
		con.on('authenticated', function () {
			log('authenticated', con.socket.sessionid);
			authenticated = true;
			alias(aliasName);
			for (var event in watching) {
				watch(event, watching[event]);
			}
			flush();
		});
		con.on('deauthenticated', function () {
			log('deauthenticated', con.socket.sessionid);
			authenticated = false;
		});
		con.on('disconnect', function () {
			log('disconnect', con.socket.sessionid );
		});
		con.on('reconnect_failed', function() {
			log('reconnect failed', con.socket.sessionid);
		});
		con.on('auth-error', function () {
			log('auth-error', con.socket.sessionid);
		});
		con.on('auth-invalid', function () {
			log('auth-invalid', con.socket.sessionid);
		});
		con.on('auth-invalid-perms', function () {
			log('auth-invalid-perms', con.socket.sessionid);
		});
		return con;
	}

	function alias(name) {
		if (!name) { return; }
		aliasName = name;
		_deliver({ event: 'alias', data: name });
	}

	function watch(event, fn) {
		if (!event || !fn) { return; }

		var socket = client();
		_deliver({ event: 'subscribe', data: event });

		var events = [].concat(event);
		for (var i = 0; i < events.length; i++) {
			var ev = events[i];
			delete socket.$events[ev];
			delete watching[ev];

			socket.on(ev, fn);
			watching[ev] = fn;
		}
	}

	function unwatch(event) {
		if (!event) { return; }

		var socket = client();
		_deliver({ event: 'unsubscribe', data: event });

		var events = [].concat(event);
		for (var i = 0; i < events.length; i++) {
			var ev = events[i];
			delete socket.$events[ev];
			delete watching[ev];
		}
	}

	function _deliver(item) {
		var socket = client();
		if (authenticated) {
			socket.emit(item.event, item.data);
		} else {
			queue.push(item);
		}
	}

	function flush() {
		var socket = client();
		while (queue.length) {
			var item = queue.shift();
			socket.emit('push', item);
		}
	}

	function log() {
		if (options.log){
			console.log('hatchet.io :: subscriber :: ', Array.prototype.slice.call(arguments));
		}
	}

	// Expose public methods
	this.alias = alias;
	this.watch = watch;
	this.unwatch = unwatch;
	this.authenticated = authenticated;
}

function subscriber(channel, secret, opts) {
	return new HatchetSubscriber(channel, secret, opts);
}

function publisher(channel, secret, opts) {
	return new HatchetPublisher(channel, secret, opts);
}

module.exports = {
	subscriber: subscriber,
	publisher: publisher
};