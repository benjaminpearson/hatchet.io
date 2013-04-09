var hatchet = require('../index.js');

// Subscriber 1
var subscriber1 = hatchet.subscriber('demo', 'sub-token', { log: true });

// Watch for 'log' events and run the defined function when it occurs
subscriber1.watch('log', function(data) {
    console.log('log', data);
});

// Publisher 1
var publisher1 = hatchet.publisher('demo', 'pub-token', { log: true });

setInterval(function() {
	publisher1.send('log', { foo: 'bar' });
}, 1000);

// Subscriber 2
var subscriber2 = hatchet.subscriber('demo', 'sub-token', { log: true });

// Watch for 'log' events and run the defined function when it occurs
subscriber2.watch('log', function(data) {
    console.log('log', data);
});

// Subscriber 3
var subscriber3 = hatchet.subscriber('demo', 'sub-token', { log: true });

// Watch for 'log' events and run the defined function when it occurs
subscriber3.watch('log', function(data) {
    console.log('log', data);
});