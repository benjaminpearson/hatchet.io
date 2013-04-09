var redis = require('redis');
var config = require('../config');

var store = redis.createClient(config.core.redis.pubsub.port, config.core.redis.pubsub.host);

module.exports = store;