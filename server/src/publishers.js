var config = require('./config');

var auth = require('./lib/auth');
var pubsub = require('./lib/pubsub');
var stats = require('./lib/stats');

var constants = require('./lib/constants');

var publishers = require('socket.io').listen(config.core.socket.publishers.port);
publishers.set('log level', config.core.socket.publishers.logLevel);

// Setup Publishers Socket
publishers.sockets.on(constants.events.CONNECT, function (socket) {

	//stats.publisher('connect', socket);

	socket.on(constants.events.AUTH, function (data) {
		data = data || {};
		data.type = 'publishers';
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
				socket.emit(constants.res.AUTH_SUCCESS);
			});
		});
	});

	socket.on(constants.events.DEAUTH, function () {
		socket.get(constants.props.AUTH, function(err, value) {
			socket.del(constants.props.AUTH, function() {
				socket.emit(constants.res.DEAUTH_SUCCESS);
			});
		});
	});

	socket.on(constants.events.MESSAGE, function (data) {
		if (!data || !data.event) return;

		socket.get(constants.props.AUTH, function(err, info) {
			if (err || !info) {
				socket.emit(constants.res.AUTH_INVALID);
				return;
			}

			var perms = info.perms;
			if (perms.indexOf('*') == -1 && perms.indexOf(data.event) == -1) {
				socket.emit(constants.res.AUTH_INVALID_PERMS);
				return;
			}

			pubsub.publish(info.channel, JSON.stringify(data));
			//stats.publisher('message', socket);
		});
	});

	socket.on(constants.events.DISCONNECT, function() {
		//stats.publisher('disconnect', socket);
	});
});