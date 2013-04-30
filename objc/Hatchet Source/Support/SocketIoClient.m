//
//	SocketIoClient.m
//	SocketIoCocoa
//
//	Created by Fred Potter on 11/11/10.
//	Copyright 2010 Fred Potter. All rights reserved.
//
//	0.7 compatibility inspired by https://github.com/pkyeck/socket.IO-objc/blob/master/SocketIO.m

#import "SocketIoClient.h"
#import "WebSocket.h"
#import "JSONKit.h"

#pragma mark NSStatefulURLConnection interface and implementation
// Source: http://www.goosoftware.co.uk/blog/adding-state-to-nsurlconnection/ 

@interface NSStatefulURLConnection : NSURLConnection {
	NSDictionary *userInfo;
	NSUInteger type;
}

@property (nonatomic, retain) NSDictionary *userInfo;
@property (readwrite, assign) NSUInteger type;

@end

@implementation NSStatefulURLConnection

@synthesize userInfo, type;

@end

#pragma mark SocketIoClient private methods

@interface SocketIoClient (PrivateMethods) <WebSocketDelegate>

- (void)checkIfConnected;
- (void)handshake;
- (void)upgrade;
- (void)notifyMessagesSent:(NSDictionary *)message;
- (void)send:(NSString *)data type:(SocketIoMessageType)type ack:(void (^)())ackBlock;
- (NSString *)encode:(NSDictionary *)message;
- (void)decode:(NSString *)data;
- (void)onTimeout;
- (void)setTimeout;
- (void)doQueue;
- (void)onConnect;
- (void)onDisconnect;
- (void)onData:(NSString *)data;
- (void)onHandshake:(NSData *)data;

@end

#pragma mark SocketIoClient implementation

@implementation SocketIoClient

@synthesize delegate = _delegate, connectTimeout = _connectTimeout, tryAgainOnConnectTimeout = _tryAgainOnConnectTimeout, 
			heartbeatTimeout = _heartbeatTimeout, heartbeatIntervalPadding = _heartbeatIntervalPadding, secureConnection = _secureConnection,
			isConnecting = _isConnecting, isConnected = _isConnected, connectRetries = connectRetries, maxConnectRetries = _maxConnectRetries;

#pragma mark Public Methods

- (id)initWithHost:(NSString *)host port:(int)port {
	if (self = [super init]) {
		_host = [host retain];
		_port = port;
		_queue = [[NSMutableArray array] retain];
		_delegate = nil;
		
		_ackCount = 0;
		_ackCallbacks = [[NSMutableDictionary alloc] init];
		
		// Set defaults
		_secureConnection = FALSE;
		_connectTimeout = 15.0; // updated on handshake
		_tryAgainOnConnectTimeout = YES;
		_connectRetries = 0; // increments on every connection failure. on connect reset to 0
		_maxConnectRetries = 3000;
		_heartbeatTimeout = 25.0; // updated on handshake
		_heartbeatIntervalPadding = 10.0; 
	}
	return self;
}

- (void)dealloc {
	[_host release];
	[_queue release];
	[_webSocket release];
	
	if (_transport) { [_transport release]; _transport = nil; }
	if (_sessionId) { [_sessionId release]; _sessionId = nil; }	
	
	[super dealloc];
}

// Connection / Disconnection

- (void)connect {
	// Begin Connecting Process
	if (!_isConnected) {
		
		if (_isConnecting) {
			[self disconnect];
		}
		
		_isConnecting = YES;
		
		// if missing sessionId and transport type, handshake, otherwise upgrade the connection
		if (!_sessionId && !_transport) {
			[self handshake];
		} else {
			[self upgrade];
		}
		
		if (_connectTimeout > 0.0) {
			[self performSelector:@selector(checkIfConnected) withObject:nil afterDelay:_connectTimeout];
		}
	}
}

- (void)disconnect {
	//Begin Disconnection Process
	[self send:nil type:SocketIoMessageTypeDisconnect ack:nil];
	[_webSocket close];
	[self onDisconnect];
}

// Send Methods

- (void)sendMessage:(NSString *)message {
	[self sendMessage:message withAcknowledgeBlock:nil];	
}

- (void)sendMessage:(NSString *)message withAcknowledgeBlock:(void (^)(id json))ackBlock {
	[self send:message type:SocketIoMessageTypeMessage ack:ackBlock];
}

- (void)sendJSON:(id)object {
	[self sendJSON:object withAcknowledgeBlock:nil];	
}

- (void)sendJSON:(id)object withAcknowledgeBlock:(void (^)(id json))ackBlock {
	[self send:[object JSONString] type:SocketIoMessageTypeJSON ack:ackBlock];
}

- (void)sendEvent:(NSString *)event withData:(id)data {
	[self sendEvent:event withData:data withAcknowledgeBlock:nil];	
}

- (void)sendEvent:(NSString *)event withData:(id)data withAcknowledgeBlock:(void (^)(id json))ackBlock {
	NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:event, @"name", data, @"args", nil];
	[self send:[content JSONString] type:SocketIoMessageTypeEvent ack:ackBlock];
}

#pragma mark Private Methods

- (void)checkIfConnected {
	if (!_isConnected) {
		[self disconnect];

		if (_tryAgainOnConnectTimeout && _connectRetries <= _maxConnectRetries) {
			_connectRetries++;
			[self connect];
		} else {
			// reached max connecteion retries or been told not to reconnect, therefore, disconnected permanently
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClientDidDisconnectPermanently:)]) {
				[_delegate socketIoClientDidDisconnectPermanently:self];
			}	
		}
	}
}

- (void)handshake {
	NSString *protocol = _secureConnection ? @"https" : @"http";
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%d/socket.io/1/", protocol, _host, _port]];
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:15];
	NSStatefulURLConnection *connection = [[NSStatefulURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	connection.type = SocketIoConnectionTypeHandshake;
	[connection start];
	 	
	if(!connection) {
 		// Handshake connection failed
 	} else {
 		// Handshake connection succeeded
 	}
	[connection release];
}

- (void)upgrade {
	// sessionId and transport must be set
	if (!_sessionId && !_transport) {
		return;
	}
	
	NSString *protocol = _secureConnection ? @"wss" : @"ws";
	
	NSString *URL = [NSString stringWithFormat:@"%@://%@:%d/socket.io/1/%@/%@", protocol, _host, _port, _transport, _sessionId];
	
	NSLog(@"Opening Websocket URL: %@", URL);
	
	// Opening Websocket
	if (_webSocket) { [_webSocket release]; _webSocket = nil; }
	_webSocket = [[WebSocket alloc] initWithURLString:URL delegate:self];
	[_webSocket open];
}

- (void)notifyMessagesSent:(NSDictionary *)message {
	NSString *data = [message objectForKey:@"data"];
	NSString *type = [message objectForKey:@"type"];

	switch ([type intValue]) {
		case SocketIoMessageTypeJSON:
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClient:didSendJSON:)]) {
				[_delegate socketIoClient:self didSendJSON:[data objectFromJSONString]];
			}
			break;
		case SocketIoMessageTypeMessage:
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClient:didSendMessage:)]) {
				[_delegate socketIoClient:self didSendMessage:data];
			}
			break;					
		case SocketIoMessageTypeEvent:
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClient:didSendEvent:withData:)]) {
				// PERFORMANCE: Decoding this after just encoding it seems like wasted CPU time
				NSDictionary *components = [data objectFromJSONString];
				[_delegate socketIoClient:self didSendEvent:[components objectForKey:@"name"] withData:[components objectForKey:@"args"]];
			}
			break;									
		default:
			break;
	}
}

- (void)send:(NSString *)data type:(SocketIoMessageType)type ack:(void (^)())ackBlock {
	data = data != nil ? data : @""; // if nil, set to empty string
	
	// Add acknowledge callback
	NSString *messageId = @"";
	if (ackBlock) {
		_ackCount++;
		messageId = [NSString stringWithFormat:@"%d", _ackCount];
		[_ackCallbacks setObject:ackBlock forKey:messageId];
	}
	
	NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys: 
							 data, @"data", 
							 messageId, @"messageId",
							 [NSNumber numberWithInt:type], @"type", 
							 nil];
	
	if (!_isConnected) {
		[_queue addObject:message];
	} else {
		[_webSocket send:[self encode:message]];
		[self notifyMessagesSent:message];
	}
}


- (NSString *)encode:(NSDictionary *)message {
	NSString *messageId = [[message objectForKey:@"messageId"] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"%@+", [message objectForKey:@"messageId"]];
	return [NSString stringWithFormat:@"%@:%@:%@:%@", [message objectForKey:@"type"], messageId, @"", [message objectForKey:@"data"]];
}

- (void)decode:(NSString *)data {
	// check if data is valid (from socket.io.js)
	NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?(.*)?$" options:NSRegularExpressionCaseInsensitive error:nil];
	NSUInteger matches = [regex numberOfMatchesInString:data options:0 range:NSMakeRange(0, [data length])];
	
	// if invalid, return empty array
	if (matches == 0) {
		[regex release];		
		return;
	}
	NSTextCheckingResult *match = [regex firstMatchInString:data options:0 range:NSMakeRange(0, [data length])];	
	[regex release];
	
	if ([match numberOfRanges] != 6) {
		return;
	}	
	NSUInteger messageType = [match rangeAtIndex:1].length == 0 ? -1 : [[data substringWithRange:[match rangeAtIndex:1]] intValue];
	//NSString *messageId = [match rangeAtIndex:2].length == 0 ? nil : [NSString stringWithString:[data substringWithRange:[match rangeAtIndex:2]]];
	//NSString *messageEndpoint = [match rangeAtIndex:3].length == 0 ? nil : [NSString stringWithString:[data substringWithRange:[match rangeAtIndex:4]]];
	NSString *messageData = [match rangeAtIndex:5].length == 0 ? nil : [NSString stringWithString:[data substringWithRange:[match rangeAtIndex:5]]];
	
	//NSLog(@"messageType: %i", messageType);
	//NSLog(@"messageId: %@", messageId);	
	//NSLog(@"messageEndpoint: %@", messageEndpoint);	
	//NSLog(@"messageData: %@", messageData);		
	
	// do stuff depending on message type
	switch (messageType) {
		case SocketIoMessageTypeDisconnect:
			//NSLog(@"Disconnect");
			[self onDisconnect];
			break;
		case SocketIoMessageTypeConnect:
			//NSLog(@"Connect");
			[self onConnect];
			break;
		case SocketIoMessageTypeHeartbeat:
			//NSLog(@"Heartbeat");
			[self send:@"" type:SocketIoMessageTypeHeartbeat ack:nil];
			break;
		case SocketIoMessageTypeMessage:
			//NSLog(@"Message");
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClient:didReceiveMessage:)]) {
				[_delegate socketIoClient:self didReceiveMessage:messageData];
			}
			break;			
		case SocketIoMessageTypeJSON:
			//NSLog(@"JSON Message");
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClient:didReceiveJSON:)]) {
				[_delegate socketIoClient:self didReceiveJSON:[messageData objectFromJSONString]];
			}
			break;
		case SocketIoMessageTypeEvent:
			//NSLog(@"Event");
			if (_delegate && [_delegate respondsToSelector:@selector(socketIoClient:didReceiveEvent:withData:)]) {
				NSDictionary *messageJSON = [messageData objectFromJSONString];
				[_delegate socketIoClient:self didReceiveEvent:[messageJSON objectForKey:@"name"] withData:[messageJSON objectForKey:@"args"]];
			}
			break;
		case SocketIoMessageTypeACK:
			//NSLog(@"ACK");
			if (messageData) {
				NSRegularExpression *ackRegex = [[NSRegularExpression alloc] initWithPattern:@"^([0-9]+)(\\+)?(.*)" options:NSRegularExpressionCaseInsensitive error:nil];
				NSTextCheckingResult *ackMatch = [ackRegex firstMatchInString:messageData options:0 range:NSMakeRange(0, [messageData length])];
				[ackRegex release];
				
				if ([ackMatch numberOfRanges] == 4) {
					NSString *ackId = [ackMatch rangeAtIndex:1].length == 0 ? nil : [messageData substringWithRange:[ackMatch rangeAtIndex:1]];
					id ackData = [ackMatch rangeAtIndex:3].length == 0 ? nil : [[messageData substringWithRange:[ackMatch rangeAtIndex:3]] objectFromJSONString];
					//NSLog(@"Acknowledgement received id %@ and data %@", ackId, ackData);
										
					if (ackId && [_ackCallbacks objectForKey:ackId]) {
						void (^callback)(id json) = [_ackCallbacks objectForKey:ackId];
						callback(ackData);
						[_ackCallbacks removeObjectForKey:ackId];
					}				
				}
			}
			break;
		case SocketIoMessageTypeError:
			//NSLog(@"Error");
			break;
		case SocketIoMessageTypeNoop:
			//NSLog(@"Noop");
			break;
		default:
			break;
	}
}

- (void)onTimeout {
	//NSLog(@"Timed out waiting for heartbeat.");
	[self onDisconnect];
}

- (void)setTimeout {
	if (_timeout != nil) {
		[_timeout invalidate];
		[_timeout release];
		_timeout = nil;
	}

	NSTimeInterval interval = _heartbeatTimeout + _heartbeatIntervalPadding;
	if (interval <= 0) {
		//NSLog(@"Warning heartbeat interval is less than 0: %f", interval);
	}
	
	_timeout = [[NSTimer scheduledTimerWithTimeInterval:interval
												 target:self
											   selector:@selector(onTimeout)
											   userInfo:nil
												repeats:NO] retain];
}

- (void)doQueue {
	if ([_queue count] > 0) {
		for (NSDictionary *message in _queue) {
			[_webSocket send:[self encode:message]];
			
			[self notifyMessagesSent:message];
		}

		[_queue removeAllObjects];
	}
}

- (void)onConnect {
	_isConnected = YES;
	_isConnecting = NO;

	_connectRetries = 0;
	
	[self doQueue];

	if (_delegate) {
		[_delegate socketIoClientDidConnect:self];
	}

	[self setTimeout];
}

- (void)onDisconnect {
	BOOL wasConnected = _isConnected;

	_isConnected = NO;
	_isConnecting = NO;

	if (_transport) { [_transport release]; _transport = nil; }
	if (_sessionId) { [_sessionId release]; _sessionId = nil; }	

	[_queue removeAllObjects];

	if (wasConnected && _delegate && [_delegate respondsToSelector:@selector(socketIoClientDidDisconnect:)]) {
		[_delegate socketIoClientDidDisconnect:self];
	}
}

- (void)onData:(NSString *)data {
	[self setTimeout];
	[self decode:data];
}

- (void)onHandshake:(NSData *)data {
	//NSLog(@"Handshake received %d bytes of data", [data length]);	
	NSString *response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if (!response) {
		NSLog(@"No response received");
		return;
	}
	
	NSLog(@"Handshake response text %@", response);
	// ie, 125653674942838444:15:25:websocket,htmlfile,xhr-polling,jsonp-polling
	
	NSArray *components = [NSArray arrayWithArray:[response componentsSeparatedByString:@":"]];
	
	if ([components count] != 4) {
		NSLog(@"Invalid socket.io handshake response");
		return;
	}
	
	// check if "websocket" is supported transport
	NSArray *transports = [[components objectAtIndex:3] componentsSeparatedByString:@","];
	if (![transports containsObject:@"websocket"]) {
		NSLog(@"websocket not a supported transport for this socket.io server");		
		return;
	}
	
	_sessionId = [[NSString alloc] initWithString:[components objectAtIndex:0]];
	_transport = [[NSString alloc] initWithString:@"websocket"];
	_heartbeatTimeout = [[components objectAtIndex:1] intValue];
	_connectTimeout = [[components objectAtIndex:2] intValue];
}

#pragma mark WebSocket Delegate Methods

- (void)webSocket:(WebSocket *)ws didFailWithError:(NSError *)error {
	//NSLog(@"Connection failed with error: %@", [error localizedDescription]);
}

- (void)webSocketDidClose:(WebSocket*)webSocket {
	//NSLog(@"Connection closed.");
	[self onDisconnect];
}

- (void)webSocketDidOpen:(WebSocket *)ws {
	//NSLog(@"Connection opened.");
}

- (void)webSocket:(WebSocket *)ws didReceiveMessage:(NSString*)message {
	////NSLog(@"Received %@", message);	
	[self onData:message];
}


#pragma mark NSStatefulURLConnection Delegate Methods

- (NSURLRequest *)connection:(NSStatefulURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	switch (connection.type) {
		case SocketIoConnectionTypeHandshake:
			//NSLog(@"Handshake connection will send request");
			break;
		default:
			//NSLog(@"Unknown connection will send request");			
			break;
	}
	return request;
}

- (void)connection:(NSStatefulURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	switch (connection.type) {
		case SocketIoConnectionTypeHandshake:
			//NSLog(@"Handshake connection received response: %@", response);
			break;
		default:
			//NSLog(@"Unknown connection received response: %@", response);			
			break;
	}
}

- (void)connection:(NSStatefulURLConnection *)connection didReceiveData:(NSData *)data {
	switch (connection.type) {
		case SocketIoConnectionTypeHandshake:
			//NSLog(@"Handshake connection received data: %@", data);
			[self onHandshake:data];
			break;
		default:
			//NSLog(@"Unknown connection received data: %@", data);			
			break;
	}
}

- (void)connection:(NSStatefulURLConnection *)connection didFailWithError:(NSError *)error {
	switch (connection.type) {
		case SocketIoConnectionTypeHandshake:
			//NSLog(@"Handshake connection error receiving response: %@", error);
			break;
		default:
			//NSLog(@"Unknown connection error receiving response: %@", error);			
			break;
	}
}

- (void)connectionDidFinishLoading:(NSStatefulURLConnection *)connection {
	switch (connection.type) {
		case SocketIoConnectionTypeHandshake:
			//NSLog(@"Handshake connection finished");
			[self upgrade];				
			break;
		default:
			//NSLog(@"Unknown connection finished");			
			break;
	}
}

@end