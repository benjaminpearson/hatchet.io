var hatchet = require('../index.js');

// Publisher
var publisher = hatchet.publisher('demo', 'pub-token', { log: true });

// Send log event
publisher.broadcast('log', { foo: 'bar' });
publisher.send('monitor', 'log', { foo: 'bar2' });

setInterval(function() {
	publisher.broadcast('log2', { foo: 'bar' });
	publisher.send('monitor', 'log', { foo: 'bar2' });
}, 5000);