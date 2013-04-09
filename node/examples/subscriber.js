var hatchet = require('../index.js');

// Subscriber
var subscriber = hatchet.subscriber('demo', 'sub-token', { log: true });

// Watch for 'log' events and run the defined function when it occurs
subscriber.watch('log', function(data) {
    console.log('abc', data);
});

subscriber.alias('test');

setTimeout(function() {
	subscriber.unwatch('log');

	setTimeout(function() {
		subscriber.watch(['log', 'log2', 'log3'], function(data) {
			console.log('123', data);
		});
	}, 2000);

}, 2000);

setTimeout(function() {
	subscriber.alias('monitor');
}, 7000);

setInterval(function() {}, 5000);