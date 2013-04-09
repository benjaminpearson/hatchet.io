# hatchet.io

Hosted (or self-hosted) socket.io service with a simple API for sending and receiving messages. It can be used for logging, analytics or any simple message broadcasting for your app.

## --- Not Production Ready. Breaking changes will be occuring often at this stage. ---

## Getting Started

Install the module with: `npm install hatchet.io`

## Documentation

_(Coming soon)_

## Examples

### Receiving Messages (Consumer)

```javascript
var hatchet = require('hatchet.io');

var consumer = hatchet.consumer('demo', 'I6mMbTSOq4rCdM', { log: true });

// Watch for 'log' events and run the defined function when it occurs
consumer.watch('log', function(data) {
    console.log('log', data);
});

// Watch another
consumer.watch('signup', function(data) {
	console.log('signup', data);
});

// You can also stop listening to an event
setTimeout(function() {
	consumer.unwatch('log');
}, 20000);
```

### Sending Messages (Contributor)

```javascript
var hatchet = require('hatchet.io');

var contributor = hatchet.contributor('demo', 'iYkrswPZVIrUMv', { log: true });

// Send 'log' event with data every 2 seconds
setInterval(function() {
	var data = {
		line: 100,
		file: 'ben.txt'
	};
	contributor.send('log', data);
}, 2000);

// Send 'signup' event with data every second
setInterval(function() {
	var data = {
		firstName: 'Frederick',
		lastName: 'Gustaveerson',
		created: new Date()
	};
	contributor.send('signup', data);
}, 1000);
```

### Options - Defaults

```javascript
{
	log: false // when enabled it will console.log out hatchet related log messages
}
```

## Contributing
Please feel free to contribute. If you see any areas for improvement, particularly in regards to performance / reliability it'd be great to receive your pull requests / comments because it's really the main crux of the application.

## Release History

### 0.0.3
- FIXED: Fixed missing alias property.

### 0.0.2

- CHANGED: Contributors now have "broadcast" and "send" that allow you to send to all users or target a specific user(s)

### 0.0.1

- FIXED: Changed the api so that you can create multiple consumers or clients from the one `require('hatchet.io')`. Previously you could only have one connection.
- CHANGED: The API for creating a connection has changed. Please see updated examples.
- ADDED: Examples scripts added.
- ADDED: Queuing for contributors if events come in prior to socket authenticating

### 0.0.0

- ADDED: Client library code that allows you to send and receive messages.

## License
Copyright (c) 2013 Ben Pearson
Licensed under the MIT license.
