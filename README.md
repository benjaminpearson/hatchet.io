# Hatchet.IO

Realtime server and client library built on Socket.IO. Simple to setup and straight forward API for sending and receiving messages, managing permissions. Goal is for everyone to feel enabled to have realtime interactions in their apps. If you are enterprise you may choose options such as PubNub or Pusher, if you are experimenting or want to roll your own infrastructure Hatchet hopefully helps.

## Getting Started

Checkout http://hatchet.io for more info.

## Documentation

More documentation coming soon. Bootstrappin at the moment.

## Examples

## NodeJS NPM Module

Install the module with: `npm install hatchet.io`

### Receiving Messages (Subscriber)

```javascript
var hatchet = require('hatchet.io');

var subscriber = hatchet.subscriber('demo', 'sub-token', { log: true });

// Watch for 'log' events and run the defined function when it occurs
subscriber.watch('log', function(data) {
    console.log('log', data);
});

// Watch another
subscriber.watch('signup', function(data) {
	console.log('signup', data);
});

// You can also stop listening to an event
setTimeout(function() {
	subscriber.unwatch('log');
}, 20000);
```

### Sending Messages (Publisher)

```javascript
var hatchet = require('hatchet.io');

var publisher = hatchet.publisher('demo', 'pub-token', { log: true });

// Send 'log' event with data every 2 seconds
setInterval(function() {
	var data = {
		line: 100,
		file: 'ben.txt'
	};
	publisher.broadcast('log', data);
}, 2000);

// Send 'signup' event with data every second
setInterval(function() {
	var data = {
		firstName: 'Frederick',
		lastName: 'Gustaveerson',
		created: new Date()
	};
	publisher.broadcast('signup', data);
}, 1000);
```

### Options - Defaults

```javascript
{
	log: false // when enabled it will console.log out hatchet related log messages
	host: 'api.hatchet.io', // change this to your Hatchet.IO instance
	ports: {
		subcribers: 5223,
		publishers: 5224
	}
}
```

## Contributing
Please feel free to contribute. If you see any areas for improvement, particularly in regards to performance / reliability / security it'd be great to receive your pull requests / comments because it's really the main crux of the application.

## Release History

### 0.0.1

- All code to date. Includes server, npm module, js client and objective c code.

## License
Copyright (c) 2013 Ben Pearson
Licensed under the MIT license.
