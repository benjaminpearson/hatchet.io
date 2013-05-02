var _ = require('underscore');
var os = require('os');

var config = require('./config');

var auth = require('./lib/auth');
var pubsub = require('./lib/pubsub');
var stats = require('./lib/stats');

var constants = require('./lib/constants');

var subscribers = require('socket.io').listen(config.core.socket.subscribers.port);
subscribers.set('log level', config.core.socket.subscribers.logLevel);
subscribers.set('close timeout', config.core.socket.subscribers.closeTimeout);

var channels = [];

// TODO: Record subscriber count
//setInterval(function() {
//	console.log(subscribers.sockets.manager.rooms);
//}, 5000);

pubsub.on('message', function(channel, message) {
	if (!_.contains(channels, channel) || !message) return;

	var data = JSON.parse(message);
	var event = data.event;
	var target = data.target;
	var payload = data.data || {};
	var once = data.once || false;

	var room = channel + ':' + (target ? 'a:' + target : 'e:' + event);
	if (once) {
		var clients = subscribers.sockets.clients(room);
		if (clients.length) {
			// Send to one random client in the room
			var client = clients[Math.floor(Math.random() * clients.length)];
			client.volatile.emit(event, payload);
		}
	} else {
		// Send to whole room
		subscribers.sockets.in(room).volatile.emit(event, payload);
	}

	// Send all messages to masters (future enhancement)
	// subscribers.sockets.in(channel + ':master').volatile.emit(event, payload);
});

// Setup Subscribers Socket
subscribers.sockets.on(constants.events.CONNECT, function (socket) {

	//stats.subscriber('connect', socket);

	socket.on(constants.events.AUTH, function (data) {
		data = data || {};
		data.type = 'subscribers';
		auth.verify(data, function(err, perms) {
			if (err) {
				socket.emit(constants.res.AUTH_ERROR);
				return;
			}
			if (!perms) {
				socket.emit(constants.res.AUTH_INVALID);
				return;
			}
			var channel = data.channel;
			socket.set(constants.props.AUTH, { channel: channel, perms: perms }, function () {
				// subscribe to pubsub for channel
				if (channels.indexOf(channel) == -1) {
					channels.push(channel);
					pubsub.subscribe(channel);
				}

				socket.emit(constants.res.AUTH_SUCCESS);
			});
		});
	});

	socket.on(constants.events.DISCONNECT, function() {
		//stats.subscriber('disconnect', socket);
	});

	// data can be an array or string
	socket.on(constants.events.ALIAS, function (name) {
		if (!name || !name.length) return;
		alias(socket, name);
	});

	// data can be an array or string
	socket.on(constants.events.SUBSCRIBE, function (data) {
		if (!data || !data.length) return;
		subscribe(socket, data);
	});

	// data can be an array or string
	socket.on(constants.events.UNSUBSCRIBE, function (data) {
		if (!data || !data.length) return;
		unsubscribe(socket, data);
	});
});

// Helper Methods

function alias(socket, name) {
	socket.get(constants.props.AUTH, function (err, info) {
		if (err || !info || !info.channel) {
			socket.emit(constants.res.AUTH_INVALID);
			return;
		}
		var channel = info.channel;
		socket.get(constants.props.ALIAS, function(err, current) {
			if (err) return;

			if (current) {
				// leave old room
				//stats.subscriber('unalias', socket, channel, current);
				//console.log('leave room', channel + ':a:' + current);
				socket.leave(channel + ':a:' + current);
			}

			// set alias and join new room
			socket.set(constants.props.ALIAS, name, function () {
				//stats.subscriber('alias', socket, channel, name);
				//console.log('join room', channel + ':a:' + name, socket.sessionid);
				socket.join(channel + ':a:' + name);
			});
		});
	});
}

function subscribe(socket, data) {
	data = data || [];
	socket.get(constants.props.AUTH, function (err, info) {
		if (err) return;
		if (!info || !info.channel) return;

		socket.get(constants.props.SUBSCRIPTIONS, function(err, existing) {
			if (err) return;

			existing = existing || [];
			var channel = info.channel;
			var perms = info.perms;
			var all = _.compact(_.uniq(_.flatten(existing.concat([data]))));
			var subscriptions = _.isEqual(perms, ['*']) ? all : _.intersection(perms, all);
			var additions = _.difference(subscriptions, existing);

			socket.set(constants.props.SUBSCRIPTIONS, subscriptions, function () {
				additions.forEach(function(sub) {
					//console.log('join room', info.channel + ':e:' + sub);
					socket.join(info.channel + ':e:' + sub);
				});

				//stats.subscriber('subscriptions', socket, subscriptions);
			});
		});
	});
}

function unsubscribe(socket, data) {
	data = data || [];

	socket.get(constants.props.AUTH, function (err, info) {
		if (err) return;

		socket.get(constants.props.SUBSCRIPTIONS, function(err, value) {
			if (err) return;

			value = value || [];
			var remove = _.compact(_.flatten([data]));
			var keep = _.difference(value, remove);

			socket.set(constants.props.SUBSCRIPTIONS, keep, function () {
				if (!info || !info.channel) return;

				remove.forEach(function(sub) {
					//console.log('leave room', info.channel + ':e:' + sub);
					socket.leave(info.channel + ':e:' + sub);
				});

				//stats.subscriber('subscriptions', socket, keep);
			});
		});
	});
}