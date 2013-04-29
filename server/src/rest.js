var express = require('express');
var config = require('./config');

var auth = require('./lib/auth');
var pubsub = require('./lib/pubsub');
var stats = require('./lib/stats');

var constants = require('./lib/constants');

var app = express();

app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(express.cookieParser());

app.use(function(req,res,next){
  res.header('Access-Control-Allow-Origin', '*');
  next();
});

// channel
// email
app.post('/create', function(req, res) {
	var params = req.body;
	if (!params || typeof params !== 'object' || !params.channel || typeof params.channel !== 'string') {
		res.json({ status: false, err: constants.res.CREATE_INVALID_NAME });
		return;
	}

	auth.create(params.channel, params.email, function(err, results) {
		res.json({
			status: !err,
			err: err ? err.message : undefined,
			results: results
		});
	});
});

// channel
// apiToken
app.post('/tokens/list', function(req, res) {
	var params = req.body;

	auth.tokens(params.channel, params.apiToken, function(err, results) {
		res.json({
			status: !err,
			err: err ? err.message : undefined,
			results: results
		});
	});
});

// channel
// apiToken
// type
// perms
app.post('/tokens/create', function(req, res) {
	var params = req.body;

	auth.addToken(params.channel, params.apiToken, params.type, params.perms, function(err, results) {
		res.json({
			status: !err,
			err: err ? err.message : undefined,
			results: results
		});
	});
});

// channel
// apiToken
// type
// token
app.post('/tokens/remove', function(req, res) {
	var params = req.body;

	auth.removeToken(params.channel, params.apiToken, params.type, params.token, function(err, results) {
		res.json({
			status: !err,
			err: err ? err.message : undefined,
			results: results
		});
	});
});

// channel
// apiToken
app.post('/remove', function(req, res) {
	var params = req.body;

	auth.remove(params.channel, params.apiToken, function(err, results) {
		res.json({
			status: !err,
			err: err ? err.message : undefined,
			results: results
		});
	});
});

app.post('/message', function(req, res) {
	var params = req.body;
	if (!params || typeof params !== 'object' || !params.auth || typeof params.auth !== 'object' ||
		!params.data || typeof params.data !== 'object' || !params.data.event) {
		res.json({ status: false, err: constants.res.AUTH_INVALID });
		return;
	}

	params.auth.type = 'publishers';
	auth.verify(params.auth, function(err, perms) {
		if (err) {
			res.json({ status: false, err: constants.res.AUTH_ERROR });
			return;
		}

		if (!perms) {
			res.json({ status: false, err: constants.res.AUTH_INVALID });
			return;
		}

		if (perms.indexOf('*') == -1 && perms.indexOf(params.data.event) == -1) {
			res.json({ status: false, err: constants.res.AUTH_INVALID_PERMS });
			return;
		}

		pubsub.publish(params.auth.channel, JSON.stringify(params.data));
		//stats.publisher('message', socket);

		res.json({ status: true });
	});
});

app.listen(config.core.rest.port);